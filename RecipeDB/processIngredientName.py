
# This script processes ingredient names from a SQL Server database using spaCy for NLP.
# It extracts nouns from the ingredient names and stores the results in IngredientName table.
# It uses SQLAlchemy for database interaction and handles incremental updates to avoid reprocessing.

import spacy
from sqlalchemy import create_engine, MetaData, Table, select, text
from sqlalchemy.exc import SQLAlchemyError

# Initialize NLP processor
print("Loading spaCy language model...")
nlp = spacy.load("en_core_web_sm")

# MSSQL Database configuration with Integrated Security
DB_CONFIG = {
    'driver': 'ODBC Driver 17 for SQL Server',
    'server': '(localdb)\\MSSQLLocalDB',
    'database': 'GroceryDB',
    'schema': 'dbo',
    'ingredients_table': 'Ingredients',
    'results_table': 'IngredientName'
}

def get_db_engine():
    """Create SQLAlchemy engine for MSSQL using Windows Authentication"""
    connection_string = (
        f"mssql+pyodbc://{DB_CONFIG['server']}/{DB_CONFIG['database']}?"
        f"driver={DB_CONFIG['driver']}&"
        f"trusted_connection=yes"
    )
    # connection_string = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=GroceryDB;Trusted_Connection=yes;"
    return create_engine(connection_string)

def extract_nouns(text):
    """Extract nouns from text using spaCy"""
    if not text or str(text).strip() == '':
        return None, None
        
    doc = nlp(str(text).lower())
    nouns = [token.lemma_ for token in doc if token.pos_ == 'NOUN']
    
    last_noun = nouns[-1] if nouns else text
    all_nouns = ' '.join(nouns) if nouns else text
    
    return last_noun, all_nouns

def get_unprocessed_ingredients(engine):
    """Retrieve only ingredients that haven't been processed yet"""
    metadata = MetaData()
    
    ingredients = Table(
        DB_CONFIG['ingredients_table'],
        metadata,
        autoload_with=engine,
        schema=DB_CONFIG['schema']
    )
    
    processed = Table(
        DB_CONFIG['results_table'],
        metadata,
        autoload_with=engine,
        schema=DB_CONFIG['schema']
    )
    
    query = select(
        ingredients.c.IngredientId,
        ingredients.c.Name
    ).select_from(
        ingredients.outerjoin(
            processed,
            ingredients.c.IngredientId == processed.c.IngredientId
        )
    ).where(
        processed.c.IngredientId == None
    )
    
    with engine.connect() as conn:
        result = conn.execute(query)
        return result.fetchall()

def process_ingredients():
    """Main processing function with incremental update support"""
    engine = get_db_engine()
    
    try:
        # Get only unprocessed ingredients
        unprocessed = get_unprocessed_ingredients(engine)
        
        if not unprocessed:
            print("No new ingredients to process")
            return
            
        print(f"Found {len(unprocessed)} new ingredients to process...")
        
        # Process in batches
        batch_size = 100
        for i in range(0, len(unprocessed), batch_size):
            batch = unprocessed[i:i + batch_size]
            processed_data = []
            
            for id, name in batch:
                try:
                    last_noun, all_nouns = extract_nouns(name)
                    processed_data.append({
                        'IngredientId': id,
                        'OriginalName': name,
                        'LastNoun': last_noun,
                        'AllNouns': all_nouns
                    })
                except Exception as e:
                    processed_data.append({
                        'IngredientId': id,
                        'OriginalName': name,
                        'LastNoun': name,
                        'AllNouns': name
                    })
            
            # Insert batch into database
            if processed_data:
                insert_stmt = f"""
                INSERT INTO {DB_CONFIG['schema']}.{DB_CONFIG['results_table']} 
                (IngredientId, OriginalName, LastNoun, Processed)
                VALUES (:IngredientId, :OriginalName, :LastNoun, :AllNouns)
                """
                with engine.begin() as conn:
                    conn.execute(text(insert_stmt), processed_data)
            
            print(f"Processed {min(i + batch_size, len(unprocessed))}/{len(unprocessed)}")
        
        print("Processing complete!")
        
    except SQLAlchemyError as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    process_ingredients()