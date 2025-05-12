/*
Stored Procedure: [GetRecommendedRecipes_MatchBoth]
Purpose: Get Recommended recipes by matching both all ingredients and major ingredients.
Parameters:
    @UserId varchar	--  string: userId
	@Cutoff_All		--	decimal: 0.00-1.00 the cutoff of match percentage for all ingredients, default: 0.7
	@Cutoff_Major	--  decimal: 0.00-1.00 the cutoff of match percentage for major ingredients, default: 0.8 
Usage:
    EXEC [GetRecommendedRecipes_MatchBoth] @UserId = '123', @Cutoff_All = 0.5, @Cutoff_Major = 0.5
*/

CREATE PROCEDURE [dbo].[GetRecommendedRecipes_MatchBoth]
    @UserId VARCHAR(254),
	@Cutoff_All Decimal(3,2) = 0.7,
	@Cutoff_Major Decimal(3,2) = 0.8
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Create temp table to store user's ingredients
    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(20));
    
    -- Get user's ingredients
    INSERT INTO @UserIngredients
    SELECT IngredientId 
    FROM UserIngredients 
    WHERE UserId = @UserId;
    
    -- Get recipes where user has sufficient ingredients
    WITH RecipeMatches AS (
        SELECT 
            r.RecipeId,
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
            r.IngredientCount,
            r.MajorIngredientCount,
            -- Count of all ingredients user has for this recipe
            (
                SELECT COUNT(*) 
                FROM RecipeIngredients ri 
                WHERE ri.RecipeId = r.RecipeId 
                AND ri.IngredientId IN (SELECT IngredientId FROM @UserIngredients)
            ) AS MatchCount,
            -- Count of major ingredients user has for this recipe
            (
                SELECT COUNT(*) 
                FROM RecipeIngredients ri 
                WHERE ri.RecipeId = r.RecipeId 
                AND ri.IsMajor = 1
                AND ri.IngredientId IN (SELECT IngredientId FROM @UserIngredients)
            ) AS MatchMajorCount
        FROM 
            Recipes r
			where r.MajorIngredientCount > 0
    )
    SELECT 
        RecipeId,
        Name,
        Instructions,
        ImageUrl,
        ReadyInMinutes,
        Servings,
        SourceUrl,
        Vegetarian,
        Vegan,
        PreparationMinutes,
        CookingMinutes,
        GlutenFree,
        VeryPopular,
        AggregateLikes,
        SourceName,
        IngredientCount,
        MajorIngredientCount,
        MatchCount,
        MatchMajorCount,
        CAST(MatchCount AS FLOAT) / NULLIF(IngredientCount, 0) AS MatchPercent,
        CAST(MatchMajorCount AS FLOAT) / NULLIF(MajorIngredientCount, 0) AS MatchMajorPercent
    FROM 
        RecipeMatches
    WHERE
        -- User has >70% of all ingredients (only if recipe has ingredients)
        (IngredientCount > 0 AND CAST(MatchCount AS FLOAT) / IngredientCount > @Cutoff_All) OR
        -- OR >80% of major ingredients (only if recipe has major ingredients)
        (MajorIngredientCount > 0 AND CAST(MatchMajorCount AS FLOAT) / MajorIngredientCount > @Cutoff_Major)
    ORDER BY
        -- Sort by highest match percentage first
        CASE 
            WHEN (IngredientCount > 0 AND CAST(MatchCount AS FLOAT) / IngredientCount > @Cutoff_All) AND
                 (MajorIngredientCount > 0 AND CAST(MatchMajorCount AS FLOAT) / MajorIngredientCount > @Cutoff_Major)
            THEN 0 -- Both conditions met (highest priority)
            WHEN (IngredientCount > 0 AND CAST(MatchCount AS FLOAT) / IngredientCount > @Cutoff_All)
            THEN 1 -- Only total ingredients condition met)
            ELSE 2 -- Only major ingredients condition met)
        END,
        -- Then sort by popularity
        AggregateLikes DESC,
        -- Then by preparation time
        ReadyInMinutes ASC;
END