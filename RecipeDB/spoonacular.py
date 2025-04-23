import requests
import time
import pyodbc
import json
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

class SpoonacularCrawler:
    def __init__(self, api_key, db_connection_string, max_workers=1, request_timeout=5):
        self.api_key = api_key
        self.db_connection_string = db_connection_string
        self.max_workers = max_workers
        self.request_timeout = request_timeout
        self.base_url = "https://api.spoonacular.com/recipes/{recipe_id}/information?includeNutrition=false&apiKey={api_key}"
        
        # Initialize database connection
        self.conn = pyodbc.connect(db_connection_string)
        self.cursor = self.conn.cursor()
        
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
            """, recipe_id, json.dumps(response), datetime.utcnow())
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
                'fetchDateTime': datetime.utcnow()
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
        recipe_id, response = self.fetch_recipe(recipe_id)
        if response:
            self.save_raw_response(recipe_id, response)
            self.parse_and_save_recipe(recipe_id, response)
        return recipe_id
    
    def crawl_recipes(self, start_id=1, end_id=None, batch_size=100):
        current_id = start_id
        processed_ids = set()
        
        # Get already processed IDs from database
        self.cursor.execute("SELECT recipeId FROM RawRecipeData")
        processed_ids.update(row[0] for row in self.cursor.fetchall())
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            while end_id is None or current_id <= end_id:
                # Prepare batch of IDs to process (skip already processed ones)
                batch = []
                while len(batch) < batch_size and (end_id is None or current_id <= end_id):
                    if current_id not in processed_ids:
                        batch.append(current_id)
                    current_id += 1
                
                if not batch:
                    if end_id is None:
                        # No more recipes to process (reached end of unknown range)
                        break
                    continue
                
                # Process batch with rate limiting
                futures = {executor.submit(self.process_recipe, rid): rid for rid in batch}
                for future in as_completed(futures):
                    rid = futures[future]
                    try:
                        future.result()
                    except Exception as e:
                        print(f"Error processing recipe {rid}: {str(e)}")
                
                # Rate limiting - sleep between batches
                time.sleep(1)
    
    def close(self):
        self.cursor.close()
        self.conn.close()

# Configuration
API_KEY = "APIKEY"
# DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=RecipeDB;UID=username;PWD=password"
DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=RecipeDB;Trusted_Connection=yes;"
# DB_CONNECTION_STRING = "Server=(localdb)\\MSSQLLocalDB;Database=GroceryDB;Trusted_Connection=True;TrustServerCertificate=True;"

# Usage
if __name__ == "__main__":
    crawler = SpoonacularCrawler(
        api_key=API_KEY,
        db_connection_string=DB_CONNECTION_STRING,
        max_workers=1,  # Keep at 1 for strict rate limiting
        request_timeout=5
    )
    
    try:
        # Start crawling from ID 1 to (unknown) - will stop when no more recipes found
        # Alternatively, set an end_id if you know the maximum
        crawler.crawl_recipes(start_id=1, end_id=3, batch_size=10)
    finally:
        crawler.close()