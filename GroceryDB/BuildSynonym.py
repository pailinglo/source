import pyodbc
from openai import OpenAI
import os
import re

# Initialize the client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Database connection settings
DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=GroceryDB;Trusted_Connection=yes;"

def get_distinct_ingredients():
    """Get distinct Curated values from IngredientName that aren't already processed"""
    conn = pyodbc.connect(DB_CONNECTION_STRING)
    
    cursor = conn.cursor()
    query = """
    SELECT DISTINCT i.Curated
    FROM IngredientName i
    WHERE NOT EXISTS (
        SELECT 1 FROM IngredientSynonyms s 
        WHERE s.Name = i.Curated
    )
    AND i.Curated IS NOT NULL
    """
    
    cursor.execute(query)
    results = [row[0] for row in cursor.fetchall()]
    cursor.close()
    conn.close()
    return results

def save_synonyms_to_db(ingredient, synonym_data):
    """Save the LLM synonyms to the database"""
    conn = pyodbc.connect(DB_CONNECTION_STRING)
    
    cursor = conn.cursor()
    
    for order, (original_synonym, clean_synonym) in enumerate(synonym_data, start=1):
        # Parse the synonym for region and misspellings
        is_misspelling = 1 if "misspelling" in original_synonym.lower() else 0
        
        # Extract region if present (looking for patterns like "(Japanese)")
        # Only look for region if it's not a misspelling
        region = None
        if not is_misspelling:
            region_match = re.search(r'\(([^)]+)\)', original_synonym)
            region = region_match.group(1) if region_match else None
        
        insert_query = """
        INSERT INTO IngredientSynonyms 
        (Name, Synonym, LLMReportOrder, IsMisspelling, Region, LLMText)
        VALUES (?, ?, ?, ?, ?, ?)
        """
        
        cursor.execute(insert_query, 
                      ingredient, clean_synonym.lower(), order, is_misspelling, region, original_synonym)
    
    conn.commit()
    cursor.close()
    conn.close()

def get_llm_synonyms(term, max_retries=3):
    """
    Get culinary synonyms using OpenAI's latest API
    Args:
        term: The ingredient term to find synonyms for
        max_retries: Number of retry attempts if API fails
    Returns:
        List of tuples: (original_synonym, cleaned_synonym) or None if failed
    """
    prompt = f"""List 5-10 culinary synonyms or alternative names for '{term}'.
    Include technical names, regional names, and common misspellings.
    Format as a bulleted list with no additional commentary.
    """
    # Example output for 'sticky rice':
    # - glutinous rice
    # - sweet rice
    # - waxy rice
    # - mochi rice
    # - khao niao (Thai)
                   
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a culinary expert assistant."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=200
            )
            
            content = response.choices[0].message.content
            synonyms = []
            
            for line in content.split("\n"):
                if line.strip():
                    original = line.strip("- ").strip()
                    clean = re.sub(r'\s*\([^)]+\)', '', original).strip()
                    synonyms.append((original, clean))
            
            return synonyms
            
        except Exception as e:
            print(f"Attempt {attempt + 1} failed: {str(e)}")
            if attempt == max_retries - 1:
                return None

def process_ingredients():
    """Main function to process all ingredients"""
    ingredients = get_distinct_ingredients()
    
    for i, ingredient in enumerate(ingredients, start=1):
        print(f"Processing {i}/{len(ingredients)}: {ingredient}")
        
        synonyms = get_llm_synonyms(ingredient)
        
        if synonyms:
            save_synonyms_to_db(ingredient, synonyms)
            print(f"Saved {len(synonyms)} synonyms for {ingredient}")
        else:
            print(f"Failed to get synonyms for {ingredient}")

if __name__ == "__main__":
    process_ingredients()