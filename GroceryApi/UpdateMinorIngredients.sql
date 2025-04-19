-- Script to update RecipeIngredients.IsMajor for curated minor ingredients
-- Sets IsMajor = 0 for minor ingredients (e.g., spices, condiments)
-- Assumes PascalCase column names (IngredientId, IsMajor, etc.)
-- Run after applying AddMajorIngredientsAndTrigger migration

BEGIN TRANSACTION;

-- Update IsMajor to 0 for minor ingredients
UPDATE RecipeIngredients
SET IsMajor = 0
WHERE IngredientId IN (
    SELECT IngredientId
    FROM Ingredients
    WHERE Name IN (
        'salt',
        'pepper',
        'garlic powder',
        'onion powder',
        'paprika',
        'cumin',
        'chili powder',
        'oregano',
        'basil',
        'thyme',
        'rosemary',
        'cinnamon',
        'nutmeg',
        'parsley',
        'dill',
        'olive oil',
        'vegetable oil',
        'butter',
        'soy sauce',
        'vinegar',
        'lemon juice',
        'lime juice',
        'mustard',
        'ketchup',
        'mayonnaise',
        'sugar',
        'brown sugar',
        'honey',
        'water',
        'flour',
        'cornstarch',
        'baking powder',
        'baking soda'
    )
);

-- Verify updates (optional)
SELECT i.Name, ri.IsMajor, COUNT(*) AS RecipeCount
FROM RecipeIngredients ri
INNER JOIN Ingredients i ON ri.IngredientId = i.IngredientId
WHERE i.Name IN (
    'salt',
    'pepper',
    'garlic powder',
    'onion powder',
    'paprika',
    'cumin',
    'chili powder',
    'oregano',
    'basil',
    'thyme',
    'rosemary',
    'cinnamon',
    'nutmeg',
    'parsley',
    'dill',
    'olive oil',
    'vegetable oil',
    'butter',
    'soy sauce',
    'vinegar',
    'lemon juice',
    'lime juice',
    'mustard',
    'ketchup',
    'mayonnaise',
    'sugar',
    'brown sugar',
    'honey',
    'water',
    'flour',
    'cornstarch',
    'baking powder',
    'baking soda'
)
GROUP BY i.Name, ri.IsMajor;

-- Verify MajorIngredientCount (optional)
SELECT r.RecipeId, r.Name, r.IngredientCount, r.MajorIngredientCount
FROM Recipes r
WHERE r.MajorIngredientCount < r.IngredientCount
ORDER BY r.MajorIngredientCount DESC;

COMMIT TRANSACTION;