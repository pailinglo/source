import os
import requests
import time
import pyodbc
import json
from datetime import datetime, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlparse

class SpoonacularCrawler:
    def __init__(self, api_key, db_connection_string, image_storage_path, 
                 max_workers=1, request_timeout=5):
        self.api_key = api_key
        self.db_connection_string = db_connection_string
        self.image_storage_path = image_storage_path
        self.max_workers = max_workers
        self.request_timeout = request_timeout
        self.base_url = "https://api.spoonacular.com/recipes/{recipe_id}/information?includeNutrition=false&apiKey={api_key}"
        
        # Ensure image storage directory exists
        os.makedirs(self.image_storage_path, exist_ok=True)
        
        # Initialize database connection
        self.conn = pyodbc.connect(db_connection_string)
        self.cursor = self.conn.cursor()
        self.processed_ids = self._load_processed_ids()

    def _load_processed_ids(self):
        """Load all already processed recipe IDs from database"""
        self.cursor.execute("SELECT recipeId FROM RawRecipeData")
        return {row[0] for row in self.cursor.fetchall()}

    def download_image(self, recipe_id, image_url):
        if not image_url:
            return False, None
        
        try:
            # Get the image file extension from URL
            parsed = urlparse(image_url)
            file_ext = os.path.splitext(parsed.path)[1].lower()
            if not file_ext:
                return False, None
                
            # Remove leading dot if present
            file_ext = file_ext[1:] if file_ext.startswith('.') else file_ext
            
            # Create filename
            filename = f"{recipe_id}.{file_ext}"
            filepath = os.path.join(self.image_storage_path, filename)
            
            # Download the image
            response = requests.get(image_url, stream=True, timeout=self.request_timeout)
            if response.status_code == 200:
                with open(filepath, 'wb') as f:
                    for chunk in response.iter_content(1024):
                        f.write(chunk)
                
                # Update database with download status
                self.cursor.execute("""
                    UPDATE Recipes 
                    SET imageDownloaded = 1, imageFileType = ?
                    WHERE id = ?
                """, file_ext, recipe_id)
                self.conn.commit()
                
                return True, file_ext
            return False, None
            
        except Exception as e:
            print(f"Error downloading image for recipe {recipe_id}: {str(e)}")
            return False, None
   
    
    def fetch_recipe(self, recipe_id):
        url = self.base_url.format(recipe_id=recipe_id, api_key=self.api_key)
        try:
            response = requests.get(url, timeout=self.request_timeout)
            if response.status_code == 200:
                return recipe_id, response.json()
            elif response.status_code == 404:
                print(f"Recipe {recipe_id} not found")
                return recipe_id, None
            else:
                print(f"Error fetching recipe {recipe_id}: HTTP {response.status_code}")
                return recipe_id, None
        except requests.Timeout:
            print(f"Timeout fetching recipe {recipe_id}")
            return recipe_id, None
        except requests.RequestException as e:
            print(f"Error fetching recipe {recipe_id}: {str(e)}")
            return recipe_id, None
    
    def save_raw_response(self, recipe_id, response):
        if response is None:
            return False
        
        try:
            self.cursor.execute("""
                INSERT INTO RawRecipeData (recipeId, rawResponse, fetchDateTime)
                VALUES (?, ?, ?)
            """, recipe_id, json.dumps(response), datetime.now(timezone.utc))
            self.conn.commit()
            return True
        except pyodbc.Error as e:
            print(f"Error saving raw response for recipe {recipe_id}: {str(e)}")
            self.conn.rollback()
            return False
    
    def parse_and_save_recipe(self, recipe_id, response):
        if response is None:
            return False
        
        try:
            # Extract recipe data
            recipe_data = {
                'id': response.get('id'),
                'image': response.get('image'),
                'title': response.get('title'),
                'readyInMinutes': response.get('readyInMinutes'),
                'servings': response.get('servings'),
                'sourceUrl': response.get('sourceUrl'),
                'vegetarian': response.get('vegetarian', False),
                'vegan': response.get('vegan', False),
                'preparationMinutes': response.get('preparationMinutes'),
                'cookingMinutes': response.get('cookingMinutes'),
                'fetchDateTime': datetime.now(timezone.utc)
            }
            
            # Save recipe
            self.cursor.execute("""
                INSERT INTO Recipes (id, image, title, readyInMinutes, servings, sourceUrl, 
                                   vegetarian, vegan, preparationMinutes, cookingMinutes, fetchDateTime)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, *recipe_data.values())
            
            # Save ingredients
            for ingredient in response.get('extendedIngredients', []):
                ingredient_data = {
                    'recipeId': recipe_data['id'],
                    'ingredientId': ingredient.get('id'),
                    'name': ingredient.get('name'),
                    'nameClean': ingredient.get('nameClean'),
                    'original': ingredient.get('original'),
                    'originalName': ingredient.get('originalName'),
                    'amount': ingredient.get('amount'),
                    'unit': ingredient.get('unit')
                }
                
                self.cursor.execute("""
                    INSERT INTO RecipeIngredients (recipeId, ingredientId, name, nameClean, 
                                                original, originalName, amount, unit)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, *ingredient_data.values())
            
            self.conn.commit()
            return True
            
        except pyodbc.Error as e:
            print(f"Error parsing/saving recipe {recipe_id}: {str(e)}")
            self.conn.rollback()
            return False
        except Exception as e:
            print(f"Unexpected error with recipe {recipe_id}: {str(e)}")
            self.conn.rollback()
            return False
    
    def process_recipe(self, recipe_id):
        # Fetch recipe data
        recipe_id, response = self.fetch_recipe(recipe_id)
        if not response:
            return False
            
        # Save raw response
        if not self.save_raw_response(recipe_id, response):
            return False
            
        # Parse and save recipe data
        if not self.parse_and_save_recipe(recipe_id, response):
            return False
            
        # Download image if available
        image_url = response.get('image')
        if image_url:
            success, file_ext = self.download_image(recipe_id, image_url)
            if success:
                print(f"Successfully downloaded image for recipe {recipe_id} as {recipe_id}.{file_ext}")
            else:
                print(f"Failed to download image for recipe {recipe_id}")
        
        return True
    
    def crawl_recipes(self, start_id=1, end_id=None, batch_size=100, force_retry_failed=False):
        current_id = start_id
        
        if force_retry_failed:
            # If forcing retry, clear the processed IDs cache
            self.processed_ids = set()
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            while end_id is None or current_id <= end_id:
                batch = []
                while len(batch) < batch_size and (end_id is None or current_id <= end_id):
                    if current_id not in self.processed_ids:
                        batch.append(current_id)
                    current_id += 1
                
                if not batch:
                    print(f"No more recipes to process in range {start_id}-{end_id or '∞'}")
                    break
                
                print(f"Processing batch: {batch[0]} to {batch[-1]}")
                
                futures = {executor.submit(self.process_recipe, rid): rid for rid in batch}
                for future in as_completed(futures):
                    rid = futures[future]
                    try:
                        success = future.result()
                        if success:
                            self.processed_ids.add(rid)  # Mark as processed
                    except Exception as e:
                        print(f"Error processing recipe {rid}: {str(e)}")
                
                time.sleep(1)  # Rate limiting
    
    def close(self):
        self.cursor.close()
        self.conn.close()

# Configuration
API_KEY = "APIKEY"
DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=RecipeDB;Trusted_Connection=yes;"
IMAGE_STORAGE_PATH = "./recipe_images"  # Directory to store downloaded images

# Usage
if __name__ == "__main__":
    crawler = SpoonacularCrawler(
        api_key=API_KEY,
        db_connection_string=DB_CONNECTION_STRING,
        image_storage_path=IMAGE_STORAGE_PATH,
        max_workers=1,
        request_timeout=5
    )
    
    try:
        # Start crawling from ID 1 to 100 (adjust as needed)
        crawler.crawl_recipes(start_id=1, end_id=6)
    finally:
        crawler.close()