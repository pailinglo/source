using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApi.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Cuisine",
                columns: table => new
                {
                    CuisineId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cuisine", x => x.CuisineId);
                });

            migrationBuilder.CreateTable(
                name: "DishType",
                columns: table => new
                {
                    DishTypeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DishType", x => x.DishTypeId);
                });

            migrationBuilder.CreateTable(
                name: "Ingredients",
                columns: table => new
                {
                    IngredientId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Ingredients", x => x.IngredientId);
                });

            migrationBuilder.CreateTable(
                name: "Recipes",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Instructions = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IngredientCount = table.Column<int>(type: "int", nullable: false),
                    MajorIngredientCount = table.Column<int>(type: "int", nullable: false),
                    ImageUrl = table.Column<string>(type: "varchar(255)", maxLength: 255, nullable: false),
                    ReadyInMinutes = table.Column<int>(type: "int", nullable: false),
                    Servings = table.Column<int>(type: "int", nullable: false),
                    SourceUrl = table.Column<string>(type: "varchar(500)", maxLength: 500, nullable: false),
                    Vegetarian = table.Column<bool>(type: "bit", nullable: false),
                    Vegan = table.Column<bool>(type: "bit", nullable: false),
                    PreparationMinutes = table.Column<int>(type: "int", nullable: false),
                    CookingMinutes = table.Column<int>(type: "int", nullable: false),
                    GlutenFree = table.Column<bool>(type: "bit", nullable: false),
                    VeryPopular = table.Column<bool>(type: "bit", nullable: false),
                    AggregateLikes = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Recipes", x => x.RecipeId);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "varchar(254)", maxLength: 254, nullable: false),
                    Email = table.Column<string>(type: "varchar(254)", maxLength: 254, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserId);
                });

            migrationBuilder.CreateTable(
                name: "RecipeCuisine",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    CuisineId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecipeCuisine", x => new { x.RecipeId, x.CuisineId });
                    table.ForeignKey(
                        name: "FK_RecipeCuisine_Cuisine_CuisineId",
                        column: x => x.CuisineId,
                        principalTable: "Cuisine",
                        principalColumn: "CuisineId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RecipeCuisine_Recipes_RecipeId",
                        column: x => x.RecipeId,
                        principalTable: "Recipes",
                        principalColumn: "RecipeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RecipeDishType",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    DishTypeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecipeDishType", x => new { x.RecipeId, x.DishTypeId });
                    table.ForeignKey(
                        name: "FK_RecipeDishType_DishType_DishTypeId",
                        column: x => x.DishTypeId,
                        principalTable: "DishType",
                        principalColumn: "DishTypeId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RecipeDishType_Recipes_RecipeId",
                        column: x => x.RecipeId,
                        principalTable: "Recipes",
                        principalColumn: "RecipeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RecipeIngredients",
                columns: table => new
                {
                    RecipeId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    IngredientId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    IsMajor = table.Column<bool>(type: "bit", nullable: false),
                    OriginalText = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    Unit = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
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
                    UserId = table.Column<string>(type: "varchar(254)", nullable: false),
                    IngredientId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false)
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
                name: "IX_RecipeCuisine_CuisineId",
                table: "RecipeCuisine",
                column: "CuisineId");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeDishType_DishTypeId",
                table: "RecipeDishType",
                column: "DishTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_RecipeIngredients_IngredientId",
                table: "RecipeIngredients",
                column: "IngredientId");

            migrationBuilder.CreateIndex(
                name: "IX_UserIngredients_IngredientId",
                table: "UserIngredients",
                column: "IngredientId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RecipeCuisine");

            migrationBuilder.DropTable(
                name: "RecipeDishType");

            migrationBuilder.DropTable(
                name: "RecipeIngredients");

            migrationBuilder.DropTable(
                name: "UserIngredients");

            migrationBuilder.DropTable(
                name: "Cuisine");

            migrationBuilder.DropTable(
                name: "DishType");

            migrationBuilder.DropTable(
                name: "Recipes");

            migrationBuilder.DropTable(
                name: "Ingredients");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
