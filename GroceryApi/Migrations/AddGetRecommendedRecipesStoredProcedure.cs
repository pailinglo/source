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
                    SELECT ingredientid FROM UserIngredients WHERE userid = @UserId;

                    SELECT r.recipeid AS RecipeId, r.name AS Name, r.ingredientcount AS IngredientCount,
                           COUNT(*) AS MatchCount, CAST(COUNT(*) AS FLOAT) / r.ingredientcount AS MatchPercent
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.recipeid = ri.recipeid
                    WHERE ri.ingredientid IN (SELECT IngredientId FROM @UserIngredients)
                    GROUP BY r.recipeid, r.name, r.ingredientcount
                    HAVING CAST(COUNT(*) AS FLOAT) / r.ingredientcount >= 0.7
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