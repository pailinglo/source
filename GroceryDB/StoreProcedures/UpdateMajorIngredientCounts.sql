-- This stored procedure updates the MajorIngredientCount in the Recipes table
-- based on the count of major ingredients in the RecipeIngredients table.
CREATE PROCEDURE [dbo].[UpdateMajorIngredientCounts]
AS
BEGIN
    SET NOCOUNT ON;
    
	UPDATE r
    SET MajorIngredientCount = ISNULL(sub.MajorCount, 0)
    FROM Recipes r
    LEFT JOIN (
        SELECT RecipeId, COUNT(ingredientId) AS MajorCount
        FROM RecipeIngredients
        WHERE IsMajor = 1
        GROUP BY RecipeId
    ) sub ON r.RecipeId = sub.RecipeId;
    
    RETURN @@ROWCOUNT; -- Returns number of rows updated
END