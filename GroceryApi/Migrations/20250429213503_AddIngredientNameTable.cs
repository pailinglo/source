using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GroceryApi.Migrations
{
    /// <inheritdoc />
    public partial class AddIngredientNameTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "IngredientName",
                columns: table => new
                {
                    IngredientId = table.Column<string>(type: "varchar(20)", maxLength: 20, nullable: false),
                    OriginalName = table.Column<string>(type: "varchar(100)", nullable: false),
                    LastNoun = table.Column<string>(type: "varchar(100)", nullable: false),
                    Processed = table.Column<string>(type: "varchar(100)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IngredientName", x => x.IngredientId);
                    table.ForeignKey(
                        name: "FK_IngredientName_Ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "Ingredients",
                        principalColumn: "IngredientId",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "IngredientName");
        }
    }
}
