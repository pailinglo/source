from flask import Flask, render_template, request
import pyodbc
import os

app = Flask(__name__)

# Database connection configuration
# DB_CONFIG = {
#     'server': 'YOUR_SERVER_NAME',
#     'database': 'GroceryDB',
#     'username': 'YOUR_USERNAME',
#     'password': 'YOUR_PASSWORD',
#     'driver': '{ODBC Driver 17 for SQL Server}'
# }

def get_db_connection():
    # conn_str = f"DRIVER={DB_CONFIG['driver']};SERVER={DB_CONFIG['server']};DATABASE={DB_CONFIG['database']};UID={DB_CONFIG['username']};PWD={DB_CONFIG['password']}"
    conn_str = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=GroceryDB;Trusted_Connection=yes;"
    return pyodbc.connect(conn_str)

@app.route('/')
def index():
    with get_db_connection() as conn:
        cursor = conn.cursor()
        
        # Get total recipes
        cursor.execute("SELECT COUNT(*) FROM Recipes")
        total_recipes = cursor.fetchone()[0]
        
        # Get recipes by cuisine
        cursor.execute("""
            SELECT c.CuisineId, c.Name, COUNT(*) as count 
            FROM RecipeCuisine rc
            JOIN Cuisine c ON rc.CuisineId = c.CuisineId
            GROUP BY c.CuisineId, c.Name
            ORDER BY count DESC
        """)
        recipes_by_cuisine = cursor.fetchall()
        
        # Get recipes by dish type
        cursor.execute("""
            SELECT dt.DishTypeId, dt.Name, COUNT(*) as count 
            FROM RecipeDishType rdt
            JOIN DishType dt ON rdt.DishTypeId = dt.DishTypeId
            GROUP BY dt.DishTypeId, dt.Name
            ORDER BY count DESC
        """)
        recipes_by_dish_type = cursor.fetchall()
        
        # Get total ingredients
        cursor.execute("SELECT COUNT(*) FROM Ingredients")
        total_ingredients = cursor.fetchone()[0]
        
    return render_template('index.html', 
                         total_recipes=total_recipes,
                         recipes_by_cuisine=recipes_by_cuisine,
                         recipes_by_dish_type=recipes_by_dish_type,
                         total_ingredients=total_ingredients)

@app.route('/search')
def search():
    search_type = request.args.get('type')
    search_term = request.args.get('q')
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        
        if search_type == 'id':
            # Search by recipe ID
            cursor.execute("""
                SELECT * FROM Recipes 
                WHERE RecipeId = ?
            """, (search_term,))
            recipe = cursor.fetchone()
            
            if recipe:
                # Get ingredients
                cursor.execute("""
                    SELECT ri.OriginalText 
                    FROM RecipeIngredients ri
                    WHERE ri.RecipeId = ?
                    ORDER BY ri.OriginalText
                """, (search_term,))
                ingredients = [row[0] for row in cursor.fetchall()]
                
                # Get cuisines
                cursor.execute("""
                    SELECT c.Name 
                    FROM RecipeCuisine rc
                    JOIN Cuisine c ON rc.CuisineId = c.CuisineId
                    WHERE rc.RecipeId = ?
                """, (search_term,))
                cuisines = [row[0] for row in cursor.fetchall()]
                
                return render_template('recipe.html', 
                                    recipe=recipe,
                                    ingredients=ingredients,
                                    cuisines=cuisines)
            else:
                return render_template('recipe.html', recipe=None)
        
        elif search_type == 'ingredient':
            # Search by ingredient
            cursor.execute("""
                SELECT r.RecipeId, r.Name 
                FROM Recipes r
                JOIN RecipeIngredients ri ON r.RecipeId = ri.RecipeId
                JOIN Ingredients i ON ri.IngredientId = i.IngredientId
                WHERE i.Name LIKE ? OR ri.OriginalText LIKE ?
                GROUP BY r.RecipeId, r.Name
            """, (f'%{search_term}%', f'%{search_term}%'))
            matching_recipes = cursor.fetchall()
            
            return render_template('index.html',
                                 search_results=matching_recipes,
                                 search_term=search_term)
        
        elif search_type == 'cuisine':
            # Search by cuisine
            cursor.execute("""
                SELECT r.RecipeId, r.Name 
                FROM Recipes r
                JOIN RecipeCuisine rc ON r.RecipeId = rc.RecipeId
                WHERE rc.CuisineId = ?
            """, (search_term,))
            cuisine_recipes = cursor.fetchall()
            
            cursor.execute("SELECT Name FROM Cuisine WHERE CuisineId = ?", (search_term,))
            cuisine_name = cursor.fetchone()[0]
            
            return render_template('index.html',
                                 search_results=cuisine_recipes,
                                 search_term=f"cuisine: {cuisine_name}")
    
    return render_template('index.html', error="Invalid search type")

if __name__ == '__main__':
    app.run(debug=True)