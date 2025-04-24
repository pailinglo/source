namespace GroceryApi.Models
{
    public class User
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public List<UserIngredient> UserIngredients { get; set; }
    }

    public class Ingredient
    {
        public string IngredientId { get; set; }
        public string Name { get; set; }
        public List<RecipeIngredient> RecipeIngredients { get; set; }
        public List<UserIngredient> UserIngredients { get; set; }
    }

    public class UserIngredient
    {
        public string UserId { get; set; }
        public string IngredientId { get; set; }
        public User User { get; set; }
        public Ingredient Ingredient { get; set; }
    }

    public class Recipe
    {
        public string RecipeId { get; set; }
        public string Name { get; set; }
        public string Instructions { get; set; }
        public int IngredientCount { get; set; }
        public int MajorIngredientCount { get; set; }
        public string Image { get; set; } // Nullable if imageDownloaded is false
        public int ReadyInMinutes { get; set; }
        public int Servings { get; set; }
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
        public string RecipeId { get; set; }
        public string IngredientId { get; set; }
        public bool IsMajor { get; set; }
        public string Original { get; set; }
        public decimal Amount { get; set; }
        public string Unit { get; set; }
        public Recipe Recipe { get; set; }
        public Ingredient Ingredient { get; set; }
    }

    public class Cuisine
    {
        public string CuisineId { get; set; }
        public string Name { get; set; }
        public List<RecipeCuisine> RecipeCuisines { get; set; }
    }

    public class DishType
    {
        public string DishTypeId { get; set; }
        public string Name { get; set; }
        public List<RecipeDishType> RecipeDishTypes { get; set; }
    }

    public class RecipeCuisine
    {
        public string RecipeId { get; set; }
        public string CuisineId { get; set; }
        public Recipe Recipe { get; set; }
        public Cuisine Cuisine { get; set; }
    }

    public class RecipeDishType
    {
        public string RecipeId { get; set; }
        public string DishTypeId { get; set; }
        public Recipe Recipe { get; set; }
        public DishType DishType { get; set; }
    }
    public class RecipeRecommendation
    {
        public string RecipeId { get; set; }
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
        public string IngredientId { get; set; }
        public string Name { get; set; }
    }
}