using Microsoft.EntityFrameworkCore.Migrations;

namespace GroceryApi.Migrations
{
    public partial class AddGetRecommendedRecipesStoredProcedure : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                CREATE PROCEDURE GetRecommendedRecipes
                    @UserId VARCHAR(50)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(50));
                    INSERT INTO @UserIngredients
                    SELECT ingredient_id FROM UserIngredients WHERE user_id = @UserId;

                    SELECT r.recipe_id AS RecipeId, r.name AS Name, r.ingredient_count AS IngredientCount,
                           COUNT(*) AS MatchCount, CAST(COUNT(*) AS FLOAT) / r.ingredient_count AS MatchPercent
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.recipe_id = ri.recipe_id
                    WHERE ri.ingredient_id IN (SELECT IngredientId FROM @UserIngredients)
                    GROUP BY r.recipe_id, r.name, r.ingredient_count
                    HAVING CAST(COUNT(*) AS FLOAT) / r.ingredient_count >= 0.7
                    ORDER BY COUNT(*) DESC;
                END
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS GetRecommendedRecipes");
        }
    }
}