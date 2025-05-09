using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GroceryApi.Models
{
    public class User
    {
        [MaxLength(254)]
        public string UserId { get; set; }
        [MaxLength(254)]
        public string Email { get; set; }
        public List<UserIngredient> UserIngredients { get; set; }
    }

    public class Ingredient
    {
        [MaxLength(20)]
        public string IngredientId { get; set; }
        [MaxLength(100)]
        public string Name { get; set; }
        public List<RecipeIngredient> RecipeIngredients { get; set; }
        public List<UserIngredient> UserIngredients { get; set; }
        public IngredientName IngredientName { get; set; }
    }

    public class UserIngredient
    {
        public string UserId { get; set; }
        [MaxLength(20)]
        public string IngredientId { get; set; }
        public User User { get; set; }
        public Ingredient Ingredient { get; set; }
    }

    public class Recipe
    {
        [MaxLength(20)]
        public string RecipeId { get; set; }
        [MaxLength(255)]
        public string Name { get; set; }
        public string Instructions { get; set; }
        public int IngredientCount { get; set; }
        public int MajorIngredientCount { get; set; }
        [MaxLength(255)]
        public string ImageUrl { get; set; } // Nullable if imageDownloaded is false
        public int ReadyInMinutes { get; set; }
        public int Servings { get; set; }
        [MaxLength(500)]
        public string SourceUrl { get; set; }
        public bool Vegetarian { get; set; }
        public bool Vegan { get; set; }
        public int PreparationMinutes { get; set; }
        public int CookingMinutes { get; set; }
        public bool GlutenFree { get; set; }
        public bool VeryPopular { get; set; }
        public int AggregateLikes { get; set; }
        public List<RecipeCuisine> RecipeCuisines { get; set; }
        public List<RecipeDishType> RecipeDishTypes { get; set; }
        public List<RecipeIngredient> RecipeIngredients { get; set; }
       
    }

    public class RecipeIngredient
    {
        [MaxLength(20)]
        public string RecipeId { get; set; }
        [MaxLength(20)]
        public string IngredientId { get; set; }
        public bool IsMajor { get; set; }
        [MaxLength(255)]
        public string OriginalText { get; set; }
        public decimal Amount { get; set; }
        public string Unit { get; set; }
        public Recipe Recipe { get; set; }
        public Ingredient Ingredient { get; set; }
    }

    public class Cuisine
    {
        [MaxLength(20)] 
        public string CuisineId { get; set; }
        [MaxLength(100)]
        public string Name { get; set; }
        public List<RecipeCuisine> RecipeCuisines { get; set; }
    }

    public class DishType
    {
        [MaxLength(20)]
        public string DishTypeId { get; set; }
        [MaxLength(100)]
        public string Name { get; set; }
        public List<RecipeDishType> RecipeDishTypes { get; set; }
    }

    public class RecipeCuisine
    {
        [MaxLength(20)]
        public string RecipeId { get; set; }
        [MaxLength(20)]
        public string CuisineId { get; set; }
        public Recipe Recipe { get; set; }
        public Cuisine Cuisine { get; set; }
    }

    public class RecipeDishType
    {
        [MaxLength(20)]
        public string RecipeId { get; set; }
        [MaxLength(20)]
        public string DishTypeId { get; set; }
        public Recipe Recipe { get; set; }
        public DishType DishType { get; set; }
    }
    public class RecipeRecommendation
    {
        [MaxLength(20)]
        public string RecipeId { get; set; }
        [MaxLength(255)]    
        public string Name { get; set; }
        public int IngredientCount { get; set; }
        public int MajorIngredientCount { get; set; }
        public int MatchCount { get; set; }
        public double MatchPercent { get; set; }
    }

    public class BatchIngredientsDto
    {
        public List<BatchIngredientItem> Items { get; set; }
    }

    public class BatchIngredientItem
    {
        public string Name { get; set; }
        public string OriginalName { get; set; }
    }

    public class IngredientDto
    {
        [MaxLength(20)]
        public string IngredientId { get; set; }
        public string Name { get; set; }
    }

    public class IngredientName
    {
        [Key]
        [ForeignKey("Ingredient")]
        [MaxLength(20)]
        public string IngredientId { get; set; }
        public string OriginalName { get; set; }
        public string LastNoun { get; set; }
        public string Processed { get; set; }
        public string Curated { get; set; }
        public Ingredient Ingredient { get; set; }
    }

    public class IngredientSynonym
    {
        public string Name { get; set; }
        public string Synonym { get; set; }
        public int LLMReportOrder { get; set; }
        public bool IsMisspelling { get; set; }
        public string Region { get; set; }
        public string LLMText { get; set; }
    }
}
