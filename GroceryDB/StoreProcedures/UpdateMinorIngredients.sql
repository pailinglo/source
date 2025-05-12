-- Script to update RecipeIngredients.IsMajor for curated minor ingredients
-- Sets IsMajor = 0 for minor ingredients (e.g., spices, condiments)

USE [GroceryDB]
GO

/****** Object:  StoredProcedure [dbo].[TransferRecipesToGroceryDB]    Script Date: 5/8/2025 2:26:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateMinorIngredients]
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
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;

