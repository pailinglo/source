USE [GroceryDB]
GO

/****** Object:  StoredProcedure [dbo].[GetRecommendedRecipes]    Script Date: 4/29/2025 4:54:30 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


                CREATE PROCEDURE [dbo].[GetRecommendedRecipes]
                    @UserId VARCHAR(50)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(50));
                    INSERT INTO @UserIngredients
                    SELECT ingredientid FROM UserIngredients WHERE userid = @UserId;

                    SELECT r.recipeid AS RecipeId, r.name AS Name, r.ingredientcount AS IngredientCount, r.MajorIngredientCount as MajorIngredientCount,
                           COUNT(*) AS MatchCount, CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount AS MatchPercent
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.recipeid = ri.recipeid
                    WHERE ri.ingredientid IN (SELECT IngredientId FROM @UserIngredients) and ri.IsMajor = 1 --only count major ingredient
                    GROUP BY r.recipeid, r.name, r.ingredientcount, r.MajorIngredientCount
                    HAVING CAST(COUNT(*) AS FLOAT) / r.ingredientcount >= 0.7
                    ORDER BY COUNT(*) DESC;
                END
            
GO