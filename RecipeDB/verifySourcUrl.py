import requests
import pyodbc
from datetime import datetime, timedelta, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed
import argparse

class UrlValidator:
    def __init__(self, db_connection_string, timeout=10, max_workers=10):
        self.db_connection_string = db_connection_string
        self.timeout = timeout
        self.max_workers = max_workers
        self.conn = pyodbc.connect(db_connection_string)
        self.cursor = self.conn.cursor()

    def initialize_url_tracking(self, start_id=None, end_id=None):
        """Populate the tracking table with existing recipes within ID range"""
        query = """
            INSERT INTO RecipeUrlStatus (RecipeId, SourceUrl)
            SELECT id, SourceUrl 
            FROM Recipes 
            WHERE SourceUrl IS NOT NULL
            AND id NOT IN (SELECT RecipeId FROM RecipeUrlStatus)
            """
        
        # Add ID range conditions if specified
        params = []
        if start_id is not None:
            query += " AND id >= ?"
            params.append(start_id)
        if end_id is not None:
            query += " AND id <= ?"
            params.append(end_id)
            
        self.cursor.execute(query, params)
        self.conn.commit()

    def check_url(self, recipe_id, url):
        """Check URL accessibility with enhanced logic"""
        if not url or not url.strip():
            return {
                'recipe_id': recipe_id,
                'status_code': None,
                'is_accessible': False,
                'error': 'Empty URL',
                'retry_count': 0
            }

        try:
            response = requests.head(
                url,
                timeout=self.timeout,
                allow_redirects=True,
                headers={'User-Agent': 'RecipeDB UrlValidator/1.0'}
            )
            
            is_accessible = 200 <= response.status_code < 400
            return {
                'recipe_id': recipe_id,
                'status_code': response.status_code,
                'is_accessible': is_accessible,
                'error': None,
                'retry_count': 0 if is_accessible else 1
            }
        except requests.RequestException as e:
            return {
                'recipe_id': recipe_id,
                'status_code': None,
                'is_accessible': False,
                'error': str(e),
                'retry_count': 1
            }

    def get_urls_to_check(self, batch_size=1000, start_id=None, end_id=None):
        """Get URLs needing verification within ID range and RetryCount < 3"""
        query = """
            SELECT RecipeId, SourceUrl, RetryCount 
            FROM RecipeUrlStatus 
            WHERE 
                (NextCheckDate IS NULL OR NextCheckDate <= GETDATE())
                AND RetryCount < 3
            """
        
        params = []
        if start_id is not None:
            query += " AND RecipeId >= ?"
            params.append(start_id)
        if end_id is not None:
            query += " AND RecipeId <= ?"
            params.append(end_id)
            
        query += """
            ORDER BY 
                CASE WHEN RetryCount = 0 THEN 0 ELSE 1 END,
                LastChecked ASC
            """
            
        self.cursor.execute(query, params)
        return self.cursor.fetchmany(batch_size)

    def update_status(self, result):
        """Update tracking table with intelligent retry scheduling"""
        retry_count = result['retry_count']
        next_check = None
        
        if not result['is_accessible'] and retry_count > 0:
            # Exponential backoff for retries (1h, 4h, 12h, 24h, 3d, 1w)
            backoff_hours = min(168, [1, 4, 12, 24, 72, 168][min(retry_count-1, 5)])
            next_check = datetime.now(timezone.utc) + timedelta(hours=backoff_hours)

        self.cursor.execute("""
            UPDATE RecipeUrlStatus 
            SET 
                IsAccessible = ?,
                LastChecked = ?,
                HttpStatus = ?,
                ErrorMessage = ?,
                RetryCount = RetryCount + ?,
                NextCheckDate = ?
            WHERE RecipeId = ?
            """,
            result['is_accessible'],
            datetime.now(timezone.utc),
            result['status_code'],
            result['error'],
            result['retry_count'],
            next_check,
            result['recipe_id']
        )
        self.conn.commit()

    def validate_urls(self, start_id=None, end_id=None):
        """Main validation process with enhanced logging"""
        print(f"Starting URL validation for IDs {start_id or 'start'} to {end_id or 'end'}...")
        self.initialize_url_tracking(start_id, end_id)
        urls_to_check = self.get_urls_to_check(start_id=start_id, end_id=end_id)
        
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = {
                executor.submit(self.check_url, row.RecipeId, row.SourceUrl): row.RecipeId
                for row in urls_to_check
            }
            
            for future in as_completed(futures):
                try:
                    result = future.result()
                    self.update_status(result)
                    status = result['status_code'] or result['error'][:30]
                    print(f"Checked {result['recipe_id']} - Status: {status}")
                except Exception as e:
                    print(f"Error processing {futures[future]}: {str(e)}")

        print(f"Completed validation of {len(urls_to_check)} URLs.")

    def close(self):
        self.cursor.close()
        self.conn.close()

def parse_arguments():
    parser = argparse.ArgumentParser(description='Validate recipe URLs')
    parser.add_argument('--start_id', type=int, help='Starting Recipe ID to process')
    parser.add_argument('--end_id', type=int, help='Ending Recipe ID to process')
    return parser.parse_args()

# Configuration
DB_CONNECTION_STRING = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\MSSQLLocalDB;DATABASE=RecipeDB;Trusted_Connection=yes;"

if __name__ == "__main__":
    # args = parse_arguments()
    validator = UrlValidator(DB_CONNECTION_STRING)
    try:
        # validator.validate_urls(start_id=args.start_id, end_id=args.end_id)
        validator.validate_urls(start_id=1, end_id=20)
    finally:
        validator.close()