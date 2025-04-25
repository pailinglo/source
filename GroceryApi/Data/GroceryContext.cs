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
            modelBuilder.Entity<User>().Property(u=>u.UserId).HasColumnType("varchar(254)");
            modelBuilder.Entity<User>().Property(u=>u.Email).HasColumnType("varchar(254)").HasDefaultValue(string.Empty); 

            modelBuilder.Entity<Ingredient>().HasKey(i => i.IngredientId);
            modelBuilder.Entity<Ingredient>().Property(i=>i.IngredientId).HasColumnType("varchar(20)");
            modelBuilder.Entity<Recipe>().HasKey(r => r.RecipeId);
            modelBuilder.Entity<Recipe>().Property(r=>r.RecipeId).HasColumnType("varchar(20)");
            modelBuilder.Entity<Recipe>()
                .Property(r => r.ImageUrl).HasColumnType("varchar(255)");
            modelBuilder.Entity<Recipe>()
                .Property(r => r.SourceUrl).HasColumnType("varchar(500)");
            modelBuilder.Entity<RecipeIngredient>()
                .HasKey(ri => new { ri.RecipeId, ri.IngredientId });
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.RecipeId).HasColumnType("varchar(20)");
            modelBuilder.Entity<RecipeIngredient>() 
                .Property(ri => ri.IngredientId).HasColumnType("varchar(20)");
            modelBuilder.Entity<UserIngredient>()
                .HasKey(ui => new { ui.UserId, ui.IngredientId });
            modelBuilder.Entity<UserIngredient>()
                .Property(ui => ui.UserId).HasColumnType("varchar(254)");
            modelBuilder.Entity<UserIngredient>()
                .Property(ui => ui.IngredientId).HasColumnType("varchar(20)");

            modelBuilder.Entity<RecipeRecommendation>()
                .HasNoKey()
                .ToView(null); // Keyless entity, not mapped to a table
            modelBuilder.Entity<RecipeRecommendation>()
                .Property(r => r.RecipeId).HasColumnType("varchar(20)");

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
            modelBuilder.Entity<Cuisine>().Property(c => c.CuisineId).HasColumnType("varchar(20)");
            modelBuilder.Entity<DishType>().HasKey(d => d.DishTypeId);
            modelBuilder.Entity<DishType>().Property(d => d.DishTypeId).HasColumnType("varchar(20)");
            
            modelBuilder.Entity<RecipeCuisine>()
                .HasKey(rc => new { rc.RecipeId, rc.CuisineId });
            modelBuilder.Entity<RecipeDishType>().Property(rd => rd.RecipeId).HasColumnType("varchar(20)");
            modelBuilder.Entity<RecipeDishType>().Property(rd => rd.DishTypeId).HasColumnType("varchar(20)");
            
            modelBuilder.Entity<RecipeDishType>()
                .HasKey(rd => new { rd.RecipeId, rd.DishTypeId });
            modelBuilder.Entity<RecipeDishType>().Property(rd => rd.RecipeId).HasColumnType("varchar(20)");
            modelBuilder.Entity<RecipeDishType>().Property(rd => rd.DishTypeId).HasColumnType("varchar(20)");    
            
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
                .Property(ri => ri.OriginalText)
                .HasMaxLength(255);
                
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Amount)
                .HasColumnType("decimal(10,2)");
                
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Unit)
                .HasMaxLength(50);
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.IsMajor)
                .HasDefaultValue(true);
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.OriginalText)
                .HasDefaultValue(string.Empty);
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Amount)
                .HasDefaultValue(0);
            modelBuilder.Entity<RecipeIngredient>()
                .Property(ri => ri.Unit)
                .HasDefaultValue(string.Empty);    

            modelBuilder.Entity<Recipe>()
                .Property(r => r.Instructions)
                .HasDefaultValue(string.Empty);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.SourceUrl)
                .HasDefaultValue(string.Empty);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.ImageUrl)
                .HasDefaultValue(string.Empty);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.IngredientCount)
                .HasDefaultValue(0);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.MajorIngredientCount)
                .HasDefaultValue(0);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.ReadyInMinutes)
                .HasDefaultValue(0);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.PreparationMinutes)
                .HasDefaultValue(0);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.CookingMinutes)
                .HasDefaultValue(0);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.Servings)
                .HasDefaultValue(1);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.Vegetarian)
                .HasDefaultValue(false);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.Vegan)
                .HasDefaultValue(false);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.GlutenFree)
                .HasDefaultValue(false);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.VeryPopular)
                .HasDefaultValue(false);
            modelBuilder.Entity<Recipe>()
                .Property(r => r.AggregateLikes)
                .HasDefaultValue(0);
        }
    }
}