from openai import OpenAI
import os

# Initialize the client
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))  # Store your key in environment variables

def get_llm_synonyms(term, max_retries=3):
    """
    Get culinary synonyms using OpenAI's latest API
    Args:
        term: The ingredient term to find synonyms for
        max_retries: Number of retry attempts if API fails
    Returns:
        List of synonyms or None if failed
    """
    prompt = f"""List 5-10 culinary synonyms or alternative names for '{term}'.
    Include technical names, regional names, and common misspellings.
    Format as a bulleted list with no additional commentary.
    Example output for 'sticky rice':
    - glutinous rice
    - sweet rice
    - waxy rice
    - mochi rice
    - khao niao (Thai)"""
    
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a culinary expert assistant."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,  # Lower for more deterministic results
                max_tokens=150
            )
            
            # Parse the response
            content = response.choices[0].message.content
            return [line.strip("- ").strip() for line in content.split("\n") if line.strip()]
            
        except Exception as e:
            print(f"Attempt {attempt + 1} failed: {str(e)}")
            if attempt == max_retries - 1:
                return None

# Example usage
synonyms = get_llm_synonyms("sticky rice")
print(synonyms)