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
        public List<RecipeIngredient> RecipeIngredients { get; set; }
    }

    public class RecipeIngredient
    {
        public string RecipeId { get; set; }
        public string IngredientId { get; set; }
        public bool IsMajor { get; set; }
        public Recipe Recipe { get; set; }
        public Ingredient Ingredient { get; set; }
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

    public class UserIngredientDto
    {
        public string IngredientId { get; set; }
    }
}