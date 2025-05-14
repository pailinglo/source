USE [GroceryDB]
GO

/****** Object:  StoredProcedure [dbo].[UpdateMajorIngredientCounts]    Script Date: 5/13/2025 6:25:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*	Based on the GPT-4 prediction, update the RecipeIngredients table
 *  to label major ingredient.
 *  Need to call UpdateMajorIngredientCounts store procedure after this.
 */
CREATE PROCEDURE [dbo].[UpdateMajorIngredients]
AS
BEGIN
    SET NOCOUNT ON;
	
    
	BEGIN TRY
        BEGIN TRANSACTION;

		UPDATE ri
		Set IsMajor = (CASE WHEN major.ingredientId is null THEN 0 ELSE 1 END)
		FROM RecipeIngredients ri
		LEFT JOIN MajorIngredientFromRecipeName major 
			ON major.RecipeId = ri.RecipeId AND major.IngredientId = ri.IngredientId AND major.LLM = 'GPT-4'

		-- This updated the MajorIngredientCount --
		UPDATE r
		SET MajorIngredientCount = ISNULL(sub.MajorCount, 0)
		FROM Recipes r
		LEFT JOIN (
			SELECT RecipeId, COUNT(ingredientId) AS MajorCount
			FROM RecipeIngredients
			WHERE IsMajor = 1
			GROUP BY RecipeId
		) sub ON r.RecipeId = sub.RecipeId;

		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

END
GO


