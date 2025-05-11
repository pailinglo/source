use RecipeDB

GO

CREATE PROCEDURE [dbo].[TransferEligibleRecipes]
AS
BEGIN
    INSERT INTO GroceryDB.dbo.Recipes (
        RecipeId, 
        Name, 
        Instructions, 
        IngredientCount, 
        MajorIngredientCount, 
        ImageUrl, 
        ReadyInMinutes, 
        Servings, 
        SourceUrl,
		SourceName,
        Vegetarian, 
        Vegan, 
        PreparationMinutes, 
        CookingMinutes, 
        GlutenFree, 
        VeryPopular, 
        AggregateLikes
    )
    SELECT 
        r.id AS RecipeId,
        r.title AS Name,
        ISNULL(r.instructions, '') AS Instructions,
        (SELECT COUNT(*) FROM RecipeDB.dbo.RecipeIngredients ri WHERE ri.recipeId = r.id) AS IngredientCount,
        -- Assuming all ingredients are major since RecipeDB doesn't have IsMajor flag
        (SELECT COUNT(*) FROM RecipeDB.dbo.RecipeIngredients ri WHERE ri.recipeId = r.id) AS MajorIngredientCount,
        r.image AS ImageUrl,
        r.readyInMinutes AS ReadyInMinutes,
        r.servings AS Servings,
        CASE WHEN rus.IsAccessible = 1 THEN r.sourceUrl ELSE '' END AS SourceUrl,
		r.sourceName,
        ISNULL(r.vegetarian, 0) AS Vegetarian,
        ISNULL(r.vegan, 0) AS Vegan,
        ISNULL(r.preparationMinutes, 0) AS PreparationMinutes,
        ISNULL(r.cookingMinutes, 0) AS CookingMinutes,
        ISNULL(r.glutenFree, 0) AS GlutenFree,
        ISNULL(r.veryPopular, 0) AS VeryPopular,
        ISNULL(r.aggregateLikes, 0) AS AggregateLikes
    FROM RecipeDB.dbo.Recipes r
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Recipes gr 
        WHERE gr.RecipeId = CAST(r.id AS varchar(20)))
END

GO

-- This procedure transfers ingredients from RecipeDB to GroceryDB.
-- In RecipeDB, the same ingredient id might have different names in NameClean or name field. 
-- This procedure is to decide which name to use:
-- 1. Prefer the most frequent nameClean (if available)
-- 2. Fall back to the most frequent name
-- 3. If frequencies are equal, pick the shortest string
-- If ingredientId is -1, disregard it.
ALTER PROCEDURE [dbo].[TransferIngredients]
AS
BEGIN
    -- Step 1: Create temp table to analyze name frequencies
    CREATE TABLE #IngredientNames (
        IngredientId INT,
        Name NVARCHAR(255),
        NameType TINYINT, -- 1=nameClean, 2=name
        Frequency INT,
        NameLength INT
    );

    -- Count frequencies of nameClean values
    INSERT INTO #IngredientNames
    SELECT 
        ingredientId,
        nameClean AS Name,
        1 AS NameType,
        COUNT(*) AS Frequency,
        LEN(nameClean) AS NameLength
    FROM RecipeDB.dbo.RecipeIngredients
    WHERE nameClean IS NOT NULL
    GROUP BY ingredientId, nameClean;

    -- Count frequencies of name values (for cases where nameClean is NULL)
    INSERT INTO #IngredientNames
    SELECT 
        ingredientId,
        name AS Name,
        2 AS NameType,
        COUNT(*) AS Frequency,
        LEN(name) AS NameLength
    FROM RecipeDB.dbo.RecipeIngredients
    WHERE (nameClean IS NULL OR nameClean = '')
    GROUP BY ingredientId, name;

    -- Step 2: Select the best name for each ingredient
    WITH RankedNames AS (
        SELECT 
            CAST(ingredientId AS VARCHAR(20)) AS IngredientId,
            Name,
            ROW_NUMBER() OVER (
                PARTITION BY ingredientId 
                ORDER BY 
                    NameType,          -- Prefer nameClean (Type 1) over name (Type 2)
                    Frequency DESC,   -- Higher frequency first
                    NameLength ASC    -- Shorter names if same frequency
            ) AS NameRank
        FROM #IngredientNames
    )
    
    -- Step 3: Insert into GroceryDB (only new ingredients)
    INSERT INTO GroceryDB.dbo.Ingredients (IngredientId, Name)
    SELECT 
        IngredientId,
        Name
    FROM RankedNames
    WHERE NameRank = 1
    AND IngredientId <> '-1' -- Exclude ingredientId = -1
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Ingredients gi 
        WHERE gi.IngredientId = RankedNames.IngredientId
    );

    DROP TABLE #IngredientNames;
END;


GO

ALTER PROCEDURE [dbo].[TransferCuisines]
AS
BEGIN
    INSERT INTO GroceryDB.dbo.Cuisine (CuisineId, Name)
    SELECT DISTINCT
        CAST(c.id AS varchar(20)) AS CuisineId,
        c.name AS Name
    FROM RecipeDB.dbo.Cuisines c
    INNER JOIN RecipeDB.dbo.RecipeCuisines rc ON c.id = rc.cuisineId
    INNER JOIN RecipeDB.dbo.Recipes r ON rc.recipeId = r.id
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Cuisine gc 
        WHERE gc.CuisineId = CAST(c.id AS varchar(20)));
END


GO

ALTER PROCEDURE [dbo].[TransferDishTypes]
AS
BEGIN
    INSERT INTO GroceryDB.dbo.DishType (DishTypeId, Name)
    SELECT DISTINCT
        CAST(dt.id AS varchar(20)) AS DishTypeId,
        dt.name AS Name
    FROM RecipeDB.dbo.DishTypes dt
    INNER JOIN RecipeDB.dbo.RecipeDishTypes rdt ON dt.id = rdt.dishTypeId
    INNER JOIN RecipeDB.dbo.Recipes r ON rdt.recipeId = r.id
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.DishType gdt 
        WHERE gdt.DishTypeId = CAST(dt.id AS varchar(20)));
END

GO

-- The same combination of (RecipeID, IngredientId) might exist in the recipeIngredients for the same recipe. 
-- The nameClean field might be the same or not, no matter what, we will choose only the first record for the same (RecipeId, IngredientID).

ALTER PROCEDURE [dbo].[TransferRecipeIngredients]
AS
BEGIN
    -- Use ROW_NUMBER() to deduplicate (RecipeId, IngredientId, NameClean)
    WITH DeduplicatedIngredients AS (
        SELECT 
            CAST(ri.recipeId AS VARCHAR(20)) AS RecipeId,
            CAST(ri.ingredientId AS VARCHAR(20)) AS IngredientId,
            ISNULL(ri.original, '') AS OriginalText,
            ISNULL(ri.amount, 0) AS Amount,
            ISNULL(ri.unit, '') AS Unit,
            ROW_NUMBER() OVER (
                PARTITION BY ri.recipeId, ri.ingredientId, ri.nameClean
                ORDER BY ri.id  -- or another deterministic field (e.g., amount DESC)
            ) AS RowNum
        FROM RecipeDB.dbo.RecipeIngredients ri
        INNER JOIN RecipeDB.dbo.Recipes r ON ri.recipeId = r.id
        LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
        WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
        AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
		AND IngredientId <> '-1'
        AND EXISTS (
            SELECT 1 FROM GroceryDB.dbo.Recipes gr 
            WHERE gr.RecipeId = CAST(r.id AS VARCHAR(20))
        )
    )
    
    INSERT INTO GroceryDB.dbo.RecipeIngredients (
        RecipeId, 
        IngredientId, 
        IsMajor, 
        OriginalText, 
        Amount, 
        Unit
    )
    SELECT 
        RecipeId,
        IngredientId,
        1 AS IsMajor,  -- Assuming all are major
        OriginalText,
        Amount,
        Unit
    FROM DeduplicatedIngredients
    WHERE RowNum = 1  -- Only keep the first record per (RecipeId, IngredientId, NameClean)
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.RecipeIngredients gri 
        WHERE gri.RecipeId = DeduplicatedIngredients.RecipeId
        AND gri.IngredientId = DeduplicatedIngredients.IngredientId
     );
END

GO

ALTER PROCEDURE [dbo].[TransferRecipeCuisines]
AS
BEGIN
    INSERT INTO GroceryDB.dbo.RecipeCuisine (RecipeId, CuisineId)
    SELECT 
        CAST(rc.recipeId AS varchar(20)) AS RecipeId,
        CAST(rc.cuisineId AS varchar(20)) AS CuisineId
    FROM RecipeDB.dbo.RecipeCuisines rc
    INNER JOIN RecipeDB.dbo.Recipes r ON rc.recipeId = r.id
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Recipes gr 
        WHERE gr.RecipeId = CAST(r.id AS varchar(20)))
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.RecipeCuisine grc 
        WHERE grc.RecipeId = CAST(rc.recipeId AS varchar(20))
        AND grc.CuisineId = CAST(rc.cuisineId AS varchar(20)));
END

GO

ALTER PROCEDURE [dbo].[TransferRecipeDishTypes]
AS
BEGIN
    INSERT INTO GroceryDB.dbo.RecipeDishType (RecipeId, DishTypeId)
    SELECT 
        CAST(rdt.recipeId AS varchar(20)) AS RecipeId,
        CAST(rdt.dishTypeId AS varchar(20)) AS DishTypeId
    FROM RecipeDB.dbo.RecipeDishTypes rdt
    INNER JOIN RecipeDB.dbo.Recipes r ON rdt.recipeId = r.id
    LEFT JOIN RecipeDB.dbo.RecipeUrlStatus rus ON r.id = rus.RecipeId
    WHERE r.imageDownloaded = 1 AND r.imageQuality is not null and r.imageQuality >= 0
    AND (r.instructions IS NOT NULL OR rus.IsAccessible = 1)
    AND EXISTS (
        SELECT 1 FROM GroceryDB.dbo.Recipes gr 
        WHERE gr.RecipeId = CAST(r.id AS varchar(20)))
    AND NOT EXISTS (
        SELECT 1 FROM GroceryDB.dbo.RecipeDishType grdt 
        WHERE grdt.RecipeId = CAST(rdt.recipeId AS varchar(20))
        AND grdt.DishTypeId = CAST(rdt.dishTypeId AS varchar(20)));
END

GO

CREATE PROCEDURE [dbo].[TransferRecipesToGroceryDB]
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Transfer eligible recipes
        EXEC [dbo].[TransferEligibleRecipes];
        
        -- Step 2: Transfer ingredients
        EXEC [dbo].[TransferIngredients];
        
        -- Step 3: Transfer cuisines
        EXEC [dbo].[TransferCuisines];
        
        -- Step 4: Transfer dish types
        EXEC [dbo].[TransferDishTypes];
        
        -- Step 5: Transfer recipe ingredients
        EXEC [dbo].[TransferRecipeIngredients];
        
        -- Step 6: Transfer recipe cuisines
        EXEC [dbo].[TransferRecipeCuisines];
        
        -- Step 7: Transfer recipe dish types
        EXEC [dbo].[TransferRecipeDishTypes];
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END