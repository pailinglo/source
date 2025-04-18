using Microsoft.EntityFrameworkCore;

namespace GroceryApi.Data
{
    public class GroceryContext : DbContext
    {
        public GroceryContext(DbContextOptions<GroceryContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<GroceryItem> GroceryItems { get; set; }
        public DbSet<Recipe> Recipes { get; set; }
        public DbSet<RecipeIngredient> RecipeIngredients { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasKey(u => u.UserId);
            modelBuilder.Entity<GroceryItem>().HasKey(g => g.ItemId);
            modelBuilder.Entity<Recipe>().HasKey(r => r.RecipeId);
            modelBuilder.Entity<RecipeIngredient>()
                .HasKey(ri => new { ri.RecipeId, ri.IngredientName });

            modelBuilder.Entity<GroceryItem>()
                .HasOne(g => g.User)
                .WithMany(u => u.GroceryItems)
                .HasForeignKey(g => g.UserId);

            modelBuilder.Entity<RecipeIngredient>()
                .HasOne(ri => ri.Recipe)
                .WithMany(r => r.Ingredients)
                .HasForeignKey(ri => ri.RecipeId);
        }
    }
}