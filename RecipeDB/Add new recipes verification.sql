

-- Before Transfer --
-- Check # of recipes --
select count(1) from RecipeDB.dbo.Recipes
select count(1) from GroceryDB.dbo.Recipes

--- Transfer validation ----
-- Step 1 - Check records crawled today --
select count(1) from RecipeDB..RawRecipeData where fetchDateTime >= GETDATE()

-- Step 2 - Check if SourceUrl is accessible --
-- Expected result = 0
select count(1) from RecipeDB..Recipes r 
left join RecipeDB..RecipeUrlStatus rus on r.id = rus.RecipeId
where r.sourceUrl is not null and rus.IsAccessible is null 

-- Step 3 - image classification --
-- Expected result = 0 - All images should be classified.
SELECT count(1) 
    FROM RecipeDB..Recipes 
    WHERE imageDownloaded = 1 AND imageQuality IS NULL

-- Step 4 - Run the DataTransfer sciprs
-- Verify before and after.
Select count(1) from GroceryDB..Recipes
Select count(1) from GroceryDB..Ingredients
select count(1) from GroceryDB..Cuisine
select count(1) from GroceryDB..DishType
Select count(1) from GroceryDB..RecipeIngredients
Select count(1) from GroceryDB..RecipeCuisine
Select count(1) from GroceryDB..RecipeDishType

-- TransferEligibleRecipes

SELECT 
        r.id AS RecipeId,
        r.title AS Name,
        ISNULL(r.instructions, '') AS Instructions,
        r.image AS ImageUrl,
		r.imageDownloaded,
		r.imageQuality,
		rus.IsAccessible,
    CASE WHEN rus.IsAccessible = 1 THEN r.sourceUrl ELSE '' END AS SourceUrl
    FROM RecipeDB.dbo.Recipes r
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Recipes gr 
        WHERE gr.RecipeId = CAST(r.id AS varchar(20)))

-- TransferIngredients: expected result = 0
Select count(1) from GroceryDB..Ingredients where IngredientId = -1


-- Check a recipeID which just added, check if its ingredient being added.
select count(1) from GroceryDB.dbo.Ingredients
select i.* from GroceryDB.dbo.Ingredients i 
inner join GroceryDB.dbo.RecipeIngredients ri on i.IngredientId = ri.IngredientId
inner join GroceryDB.dbo.Recipes r on r.RecipeId = ri.RecipeId
where r.RecipeId = '25931'

-- Step 5 - Process ingredient name

--select * from GroceryDB..Ingredients i
--left join GroceryDB..IngredientName n on i.IngredientId = n.IngredientId
--where n.IngredientId is null or n.Processed is null

--select count(1) from GroceryDB..IngredientName
select * from GroceryDB..IngredientName n where Curated is null
select * from GroceryDB..IngredientNameArchive n where Curated is not null

-- update from the IngredientNameArchive table.
begin transaction
UPDATE n
SET n.Curated = na.Curated
FROM GroceryDB.dbo.IngredientName n
INNER JOIN GroceryDB.dbo.IngredientNameArchive na 
    ON n.IngredientId = na.IngredientId
WHERE na.Curated is not null

commit transaction




