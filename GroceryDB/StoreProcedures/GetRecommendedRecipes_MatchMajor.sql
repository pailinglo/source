USE [GroceryDB]
GO

/****** Object:  StoredProcedure [dbo].[GetRecommendedRecipes_MatchMajor]    Script Date: 5/11/2025 9:37:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
Stored Procedure: [GetRecommendedRecipes_MatchMajor]
Purpose: Get Recommended recipes by matching with major ingredients
Parameters:
    @UserId varchar	--  string: userId
	@MatchPercentCutoff		--	decimal: 0.00-1.00 the cutoff of match percentage for all ingredients, default: 0.7
Usage:
    EXEC [GetRecommendedRecipes_MatchMajor] @UserId = '123', @@MatchPercentCutoff = 0.7
*/


                CREATE PROCEDURE [dbo].[GetRecommendedRecipes_MatchMajor]
                    @UserId VARCHAR(50),
					@MatchPercentCutoff Decimal(3,2) = 0.8
                AS
                BEGIN
                    SET NOCOUNT ON;
                    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(50));
                    INSERT INTO @UserIngredients
                    SELECT ingredientid FROM UserIngredients WHERE userid = @UserId;

                    SELECT	r.recipeid AS RecipeId, 
							r.name AS Name, 							
							r.Instructions,
							r.ImageUrl,
							r.ReadyInMinutes,
							r.Servings,
							r.SourceUrl,
							r.Vegetarian,
							r.Vegan,
							r.PreparationMinutes,
							r.CookingMinutes,
							r.GlutenFree,
							r.VeryPopular,
							r.AggregateLikes,
							r.SourceName,
							r.ingredientcount AS IngredientCount, 
							r.MajorIngredientCount as MajorIngredientCount,
                           COUNT(*) AS MatchCount, 
						   CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount AS MatchPercent,
						   COUNT(*) AS MatchMajorCount, -- duplicate to avoid coding errors.
						   CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount AS MatchMajorPercent	
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.recipeid = ri.recipeid
                    WHERE ri.ingredientid IN (SELECT IngredientId FROM @UserIngredients) and ri.IsMajor = 1
                    GROUP BY r.RecipeId,
						r.Name,
						r.Instructions,
						r.ImageUrl,
						r.ReadyInMinutes,
						r.Servings,
						r.SourceUrl,
						r.Vegetarian,
						r.Vegan,
						r.PreparationMinutes,
						r.CookingMinutes,
						r.GlutenFree,
						r.VeryPopular,
						r.AggregateLikes,
						r.SourceName,
						r.ingredientcount, 
						r.MajorIngredientCount
                    HAVING CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount >= @MatchPercentCutoff
                    ORDER BY COUNT(*) DESC, 
						r.AggregateLikes DESC,
						-- Then by preparation time
						r.ReadyInMinutes ASC;
                END
GO


