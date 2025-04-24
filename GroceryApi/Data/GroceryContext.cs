using Microsoft.EntityFrameworkCore;
using GroceryApi.Models;

namespace GroceryApi.Data
{
    public class GroceryContext : DbContext
    {
        public GroceryContext(DbContextOptions<GroceryContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Ingredient> Ingredients { get; set; }
        public DbSet<Recipe> Recipes { get; set; }
        public DbSet<RecipeIngredient> RecipeIngredients { get; set; }
        public DbSet<UserIngredient> UserIngredients { get; set; }
        public DbSet<RecipeRecommendation> RecipeRecommendations { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>().HasKey(u => u.UserId);
            modelBuilder.Entity<Ingredient>().HasKey(i => i.IngredientId);
            modelBuilder.Entity<Recipe>().HasKey(r => r.RecipeId);
            modelBuilder.Entity<RecipeIngredient>()
                .HasKey(ri => new { ri.RecipeId, ri.IngredientId });
            modelBuilder.Entity<UserIngredient>()
                .HasKey(ui => new { ui.UserId, ui.IngredientId });

            modelBuilder.Entity<RecipeRecommendation>()
                .HasNoKey()
                .ToView(null); // Keyless entity, not mapped to a table

            modelBuilder.Entity<RecipeIngredient>()
                .HasOne(ri => ri.Recipe)
                .WithMany(r => r.RecipeIngredients)
                .HasForeignKey(ri => ri.RecipeId);

            modelBuilder.Entity<RecipeIngredient>()
                .HasOne(ri => ri.Ingredient)
                .WithMany(i => i.RecipeIngredients)
                .HasForeignKey(ri => ri.IngredientId);

            modelBuilder.Entity<UserIngredient>()
                .HasOne(ui => ui.User)
                .WithMany(u => u.UserIngredients)
                .HasForeignKey(ui => ui.UserId);

            modelBuilder.Entity<UserIngredient>()
                .HasOne(ui => ui.Ingredient)
                .WithMany(i => i.UserIngredients)
                .HasForeignKey(ui => ui.IngredientId);
            
            modelBuilder.Entity<Cuisine>().HasKey(c => c.CuisineId);
            modelBuilder.Entity<DishType>().HasKey(d => d.DishTypeId);
            
            modelBuilder.Entity<RecipeCuisine>()
                .HasKey(rc => new { rc.RecipeId, rc.CuisineId });
                
            modelBuilder.Entity<RecipeDishType>()
                .HasKey(rd => new { rd.RecipeId, rd.DishTypeId });
                
            modelBuilder.Entity<RecipeCuisine>()
                .HasOne(rc => rc.Recipe)
                .WithMany(r => r.RecipeCuisines)
                .HasForeignKey(rc => rc.RecipeId);
                
            modelBuilder.Entity<RecipeCuisine>()
                .HasOne(rc => rc.Cuisine)
                .WithMany(c => c.RecipeCuisines)
                .HasForeignKey(rc => rc.CuisineId);
                
            modelBuilder.Entity<RecipeDishType>()
                .HasOne(rd => rd.Recipe)
                .WithMany(r => r.RecipeDishTypes)
                .HasForeignKey(rd => rd.RecipeId);
                
            modelBuilder.Entity<RecipeDishType>()
                .HasOne(rd => rd.DishType)
                .WithMany(d => d.RecipeDishTypes)
                .HasForeignKey(rd => rd.DishTypeId);
                
            // Configure RecipeIngredient updates
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Original)
                .HasMaxLength(255);
                
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Amount)
                .HasColumnType("decimal(10,2)");
                
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Unit)
                .HasMaxLength(50);
        }
    }
}