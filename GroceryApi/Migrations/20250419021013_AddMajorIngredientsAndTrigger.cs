using Microsoft.EntityFrameworkCore.Migrations;

namespace GroceryApi.Migrations
{
    public partial class AddMajorIngredientsAndTrigger : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add IsMajor to RecipeIngredients
            migrationBuilder.AddColumn<bool>(
                name: "IsMajor",
                table: "RecipeIngredients",
                nullable: false,
                defaultValue: true);

            // Add MajorIngredientCount to Recipes
            migrationBuilder.AddColumn<int>(
                name: "MajorIngredientCount",
                table: "Recipes",
                nullable: false,
                defaultValue: 0);

            // Initialize MajorIngredientCount (assume all existing ingredients are major)
            migrationBuilder.Sql(@"
                UPDATE Recipes
                SET MajorIngredientCount = IngredientCount;
            ");

            // Create trigger for IngredientCount and MajorIngredientCount
            migrationBuilder.Sql(@"
                CREATE TRIGGER UpdateIngredientCounts
                ON RecipeIngredients
                AFTER INSERT, DELETE
                AS
                BEGIN
                    SET NOCOUNT ON;
                    UPDATE r
                    SET IngredientCount = (
                        SELECT COUNT(*) 
                        FROM RecipeIngredients ri 
                        WHERE ri.RecipeId = r.RecipeId
                    ),
                    MajorIngredientCount = (
                        SELECT COUNT(*) 
                        FROM RecipeIngredients ri 
                        WHERE ri.RecipeId = r.RecipeId AND ri.IsMajor = 1
                    )
                    FROM Recipes r
                    WHERE r.RecipeId IN (
                        SELECT RecipeId FROM inserted
                        UNION
                        SELECT RecipeId FROM deleted
                    );
                END
            ");

            // Update stored procedure to count major ingredients
            migrationBuilder.Sql(@"
                DROP PROCEDURE IF EXISTS GetRecommendedRecipes;
                CREATE PROCEDURE GetRecommendedRecipes
                    @UserId VARCHAR(50)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(50));
                    INSERT INTO @UserIngredients
                    SELECT IngredientId FROM UserIngredients WHERE UserId = @UserId;

                    SELECT r.RecipeId AS RecipeId, r.Name AS Name, 
                           r.IngredientCount AS IngredientCount, 
                           r.MajorIngredientCount AS MajorIngredientCount,
                           COUNT(*) AS MatchCount, 
                           CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount AS MatchPercent
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.RecipeId = ri.RecipeId
                    WHERE ri.IngredientId IN (SELECT IngredientId FROM @UserIngredients)
                    AND ri.IsMajor = 1
                    GROUP BY r.RecipeId, r.Name, r.IngredientCount, r.MajorIngredientCount
                    HAVING CAST(COUNT(*) AS FLOAT) / r.MajorIngredientCount >= 0.7
                    ORDER BY COUNT(*) DESC;
                END
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP TRIGGER IF EXISTS UpdateIngredientCounts");
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS GetRecommendedRecipes");
            migrationBuilder.DropColumn(name: "IsMajor", table: "RecipeIngredients");
            migrationBuilder.DropColumn(name: "MajorIngredientCount", table: "Recipes");

            // Restore original stored procedure
            migrationBuilder.Sql(@"
                CREATE PROCEDURE GetRecommendedRecipes
                    @UserId VARCHAR(50)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    DECLARE @UserIngredients TABLE (IngredientId VARCHAR(50));
                    INSERT INTO @UserIngredients
                    SELECT IngredientId FROM UserIngredients WHERE UserId = @UserId;

                    SELECT r.RecipeId AS RecipeId, r.Name AS Name, r.IngredientCount AS IngredientCount,
                           COUNT(*) AS MatchCount, CAST(COUNT(*) AS FLOAT) / r.IngredientCount AS MatchPercent
                    FROM Recipes r
                    INNER JOIN RecipeIngredients ri ON r.RecipeId = ri.RecipeId
                    WHERE ri.IngredientId IN (SELECT IngredientId FROM @UserIngredients)
                    GROUP BY r.RecipeId, r.Name, r.IngredientCount
                    HAVING CAST(COUNT(*) AS FLOAT) / r.IngredientCount >= 0.7
                    ORDER BY COUNT(*) DESC;
                END
            ");
        }
    }
}