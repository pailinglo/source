namespace GroceryApi.Models
{
    public class User
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public List<GroceryItem> GroceryItems { get; set; }
    }

    public class GroceryItem
    {
        public string ItemId { get; set; }
        public string UserId { get; set; }
        public string Name { get; set; }
        public User User { get; set; }
    }

    public class Recipe
    {
        public string RecipeId { get; set; }
        public string Name { get; set; }
        public string Instructions { get; set; }
        public int IngredientCount { get; set; }
        public List<RecipeIngredient> Ingredients { get; set; }
    }

    public class RecipeIngredient
    {
        public string RecipeId { get; set; }
        public string IngredientName { get; set; }
        public Recipe Recipe { get; set; }
    }

    public class RecipeRecommendation
    {
        public string RecipeId { get; set; }
        public string Name { get; set; }
        public int MatchCount { get; set; }
        public double MatchPercent { get; set; }
    }
}