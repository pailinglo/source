using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApi.Migrations
{
    /// <inheritdoc />
    public partial class GetRecommendedRecipes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "CookingMinutes",
                table: "Recipes",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int");

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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "CookingMinutes",
                table: "Recipes",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldDefaultValue: 0);

            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS GetRecommendedRecipes");
        }
    }
}
