-- Script to update RecipeIngredients.IsMajor for curated minor ingredients
-- Sets IsMajor = 0 for minor ingredients (e.g., spices, condiments)
USE [GroceryDB]
GO

/****** Object:  StoredProcedure [dbo].[UpdateMinorIngredients]    Script Date: 5/13/2025 6:40:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[UpdateMinorIngredients]
AS
BEGIN
    SET NOCOUNT ON;
	
    
	BEGIN TRY
        BEGIN TRANSACTION;
		-- Update IsMajor to 0 for minor ingredients
		UPDATE RecipeIngredients
		SET IsMajor = 0
		WHERE IngredientId IN (
			SELECT i.IngredientId
			FROM Ingredients i
			inner join IngredientName n on i.IngredientId = n.IngredientId
			inner join MinorIngredients minor on minor.ingredient_name = n.curated

			Union
			SELECT i.IngredientId
			FROM Ingredients i
			inner join IngredientName n on i.IngredientId = n.IngredientId
			inner join IngredientSynonyms syn on syn.Name = n.Curated
			inner join MinorIngredients minor on minor.ingredient_name = syn.Synonym and syn.LLMReportOrder <=3
		)

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
END;

GO


