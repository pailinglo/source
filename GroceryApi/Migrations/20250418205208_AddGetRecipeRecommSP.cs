using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApi.Migrations
{
    /// <inheritdoc />
    public partial class AddGetRecipeRecommSP : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Ingredients",
                columns: table => new
                {
                    IngredientId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Ingredients", x => x.IngredientId);
                });

            migrationBuilder.CreateTable(
                name: "Recipes",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Instructions = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IngredientCount = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Recipes", x => x.RecipeId);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserId);
                });

            migrationBuilder.CreateTable(
                name: "RecipeIngredients",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    IngredientId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecipeIngredients", x => new { x.RecipeId, x.IngredientId });
                    table.ForeignKey(
                        name: "FK_RecipeIngredients_Ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "Ingredients",
                        principalColumn: "IngredientId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RecipeIngredients_Recipes_RecipeId",
                        column: x => x.RecipeId,
                        principalTable: "Recipes",
                        principalColumn: "RecipeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserIngredients",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    IngredientId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserIngredients", x => new { x.UserId, x.IngredientId });
                    table.ForeignKey(
                        name: "FK_UserIngredients_Ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "Ingredients",
                        principalColumn: "IngredientId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserIngredients_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RecipeIngredients_IngredientId",
                table: "RecipeIngredients",
                column: "IngredientId");

            migrationBuilder.CreateIndex(
                name: "IX_UserIngredients_IngredientId",
                table: "UserIngredients",
                column: "IngredientId");
            
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
            migrationBuilder.DropTable(
                name: "RecipeIngredients");

            migrationBuilder.DropTable(
                name: "UserIngredients");

            migrationBuilder.DropTable(
                name: "Recipes");

            migrationBuilder.DropTable(
                name: "Ingredients");

            migrationBuilder.DropTable(
                name: "Users");
        
            migrationBuilder.Sql("DROP PROCEDURE IF EXISTS GetRecommendedRecipes");
        
        }
    }
}
