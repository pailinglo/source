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
            # Extract all recipe data including new fields
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
                'glutenFree': response.get('glutenFree', False),
                'veryPopular': response.get('veryPopular', False),
                'aggregateLikes': response.get('aggregateLikes'),
                'instructions': response.get('instructions'),
                'fetchDateTime': datetime.now(timezone.utc)
            }
            
            # Save recipe (updated with new fields)
            self.cursor.execute("""
                INSERT INTO Recipes (
                    id, image, title, readyInMinutes, servings, sourceUrl, 
                    vegetarian, vegan, preparationMinutes, cookingMinutes,
                    glutenFree, veryPopular, aggregateLikes, instructions, fetchDateTime
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, *recipe_data.values())
            
            # Save ingredients (unchanged)
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
                    INSERT INTO RecipeIngredients (
                        recipeId, ingredientId, name, nameClean, 
                        original, originalName, amount, unit
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, *ingredient_data.values())
            
            # Save cuisines (array handling)
            for cuisine in response.get('cuisines', []):
                # Ensure cuisine exists in lookup table
                self.cursor.execute("""
                    MERGE INTO Cuisines WITH (HOLDLOCK) AS target
                    USING (SELECT ? AS name) AS source
                    ON target.name = source.name
                    WHEN NOT MATCHED THEN INSERT (name) VALUES (source.name);
                """, cuisine)
                
                # Get cuisine ID
                self.cursor.execute("SELECT id FROM Cuisines WHERE name = ?", cuisine)
                cuisine_id = self.cursor.fetchone()[0]
                
                # Link recipe to cuisine
                self.cursor.execute("""
                    INSERT INTO RecipeCuisines (recipeId, cuisineId)
                    VALUES (?, ?)
                """, recipe_data['id'], cuisine_id)
            
            # Save dish types (array handling)
            for dish_type in response.get('dishTypes', []):
                # Ensure dish type exists in lookup table
                self.cursor.execute("""
                    MERGE INTO DishTypes WITH (HOLDLOCK) AS target
                    USING (SELECT ? AS name) AS source
                    ON target.name = source.name
                    WHEN NOT MATCHED THEN INSERT (name) VALUES (source.name);
                """, dish_type)
                
                # Get dish type ID
                self.cursor.execute("SELECT id FROM DishTypes WHERE name = ?", dish_type)
                dish_type_id = self.cursor.fetchone()[0]
                
                # Link recipe to dish type
                self.cursor.execute("""
                    INSERT INTO RecipeDishTypes (recipeId, dishTypeId)
                    VALUES (?, ?)
                """, recipe_data['id'], dish_type_id)
            
            self.conn.commit()
            return True
            
        except pyodbc.Error as e:
            print(f"Database error with recipe {recipe_id}: {str(e)}")
            self.conn.rollback()
            return False
        except Exception as e:
            print(f"Unexpected error with recipe {recipe_id}: {str(e)}")
            self.conn.rollback()
            return False
            
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

    def get_last_recipe_id(self):
        """Get the highest recipe ID currently in the database"""
        self.cursor.execute("SELECT MAX(recipeId) FROM RawRecipeData")
        result = self.cursor.fetchone()
        return result[0] if result[0] is not None else 0

    
    def crawl_recipes(self, start_id=None, number_to_crawl=1500, batch_size=100, force_retry_failed=False):
        """
        Crawl recipes with smart defaults:
        - Defaults to 1500 recipes if number_to_crawl not specified
        - Starts from last recipe ID + 1 if start_id not specified
        
        Args:
            start_id (int): First recipe ID to crawl (None to auto-detect)
            number_to_crawl (int): Total recipes to crawl (default 1500)
            batch_size (int): Number of recipes per batch (default 100)
            force_retry_failed (bool): Retry failed recipes (default False)
        """
        # Determine starting ID
        if start_id is None:
            start_id = self.get_last_recipe_id() + 1
            print(f"Auto-starting from recipe ID {start_id}")

        current_id = start_id
        processed_count = 0
        last_successful_id = start_id - 1
        
        if force_retry_failed:
            self.processed_ids = set()
        else:
            self.processed_ids = self._load_processed_ids()
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            while processed_count < number_to_crawl:
                batch = []
                # Prepare next batch
                while len(batch) < batch_size and (processed_count + len(batch)) < number_to_crawl:
                    if current_id not in self.processed_ids:
                        batch.append(current_id)
                    current_id += 1
                
                if not batch:
                    print(f"No more recipes found. Reached ID {last_successful_id}")
                    break
                
                print(f"Processing IDs {batch[0]} to {batch[-1]} ({processed_count}/{number_to_crawl} processed)")
                
                # Process batch
                futures = {executor.submit(self.process_recipe, rid): rid for rid in batch}
                for future in as_completed(futures):
                    rid = futures[future]
                    try:
                        success = future.result()
                        if success:
                            processed_count += 1
                            last_successful_id = rid
                            self.processed_ids.add(rid)
                    except Exception as e:
                        print(f"Error processing recipe {rid}: {str(e)}")
                
                time.sleep(1)  # Rate limiting
        
        print(f"Completed crawling {processed_count} recipes (target: {number_to_crawl})")
        print(f"Last successful ID: {last_successful_id}")
    
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
        # Start crawling from Last crowled ID and crawled number_to_crawl records.
        crawler.crawl_recipes(number_to_crawl=100)
    finally:
        crawler.close()