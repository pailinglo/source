import pyodbc
from fastai.vision.all import *
from pathlib import Path
import os


# Configuration
MODEL_PATH = "C:\\Users\\paili\\recipe_images\\recipeimage_OK_classifier.pkl"
IMAGES_FOLDER = "C:\\Users\\paili\\recipe_images"
DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=RecipeDB;Trusted_Connection=yes;"


# Prediction mapping (model outputs to your integer values)
QUALITY_MAPPING = {
    "1": "good",
    "0": "poor",
    "-1": "bad quality",
    "-2": "placeholder"
}

def get_db_connection():
    return pyodbc.connect(DB_CONNECTION_STRING)

def process_records():
    # Load model
    learn = load_learner(MODEL_PATH)
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        
        # Fetch records to process
        cursor.execute("""
            SELECT id, imageFileType 
            FROM Recipes 
            WHERE imageDownloaded = 1 AND imageQuality IS NULL
        """)
        records = cursor.fetchall()
        
        total_records = len(records)
        print(f"Found {total_records} records to process")
        
        for i, (recipe_id, file_type) in enumerate(records, 1):
            try:
                # Print progress every 100 records
                if i % 100 == 0 or i == total_records:
                    print(f"Processing record {i} of {total_records} ({i/total_records:.1%})")
                
                # Construct image path
                img_name = f"{recipe_id}.{file_type}"
                img_path = Path(IMAGES_FOLDER) / img_name
                
                if not img_path.exists():
                    print(f"Image not found: {img_name}")
                    continue
                
                # Make prediction
                img = PILImage.create(img_path)
                pred_class, _, _ = learn.predict(img)
                
                # Map prediction to quality value
                quality = QUALITY_MAPPING.get(str(pred_class))
                if quality is None:
                    print(f"Unknown prediction: {pred_class} for {img_name}")
                    continue
                
                # Update database
                cursor.execute("""
                    UPDATE Recipes 
                    SET imageQuality = ? 
                    WHERE id = ?
                """, (pred_class, recipe_id))
                conn.commit()
                
                # Only print success for every 100 records to reduce clutter
                if i % 100 == 0 or i == total_records:
                    print(f"Updated {img_name}: {pred_class} -> {quality}")
                
            except Exception as e:
                print(f"Error processing {recipe_id}: {str(e)}")
                conn.rollback()

if __name__ == "__main__":
    process_records()
    print("Processing complete")