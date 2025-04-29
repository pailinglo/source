using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApi.Migrations
{
    /// <inheritdoc />
    public partial class AddMajorIngredientsAndTrigger : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Drop trigger
            migrationBuilder.Sql("DROP TRIGGER IF EXISTS UpdateIngredientCounts");

        }
    }
}
