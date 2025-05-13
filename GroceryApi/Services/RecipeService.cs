using System.Text.RegularExpressions;
using GroceryApi.Data;
using GroceryApi.Models;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace GroceryApi.Services
{
    public class RecipeService
    {
        private readonly GroceryContext _context;

        public RecipeService(GroceryContext context)
        {
            _context = context;
        }

        public async Task<RecipeDto?> GetRecipe(string recipeId)
        {
            var r = await _context.Recipes
                .Include(r => r.RecipeIngredients)
                .Include(r => r.RecipeCuisines)
                    .ThenInclude(rc => rc.Cuisine)
                .Include(r => r.RecipeDishTypes)
                    .ThenInclude(rd => rd.DishType)
                .FirstOrDefaultAsync(r => r.RecipeId == recipeId);

            if (r == null)
            {
                return null; // Return null explicitly for nullable type
            }

             return new RecipeDto
            {
                RecipeId = r.RecipeId,
                Name = r.Name,
                Instructions = GetRecipeInstructions(r.Instructions),
                ImageUrl = r.ImageUrl,
                ReadyInMinutes = r.ReadyInMinutes,
                Servings = r.Servings,
                Vegetarian = r.Vegetarian,
                Vegan = r.Vegan,
                GlutenFree = r.GlutenFree,
                IngredientCount = r.IngredientCount,
                MajorIngredientCount = r.MajorIngredientCount,
                SourceUrl = r.SourceUrl,
                SourceName = r.SourceName,
                PreparationMinutes = r.PreparationMinutes,
                CookingMinutes = r.CookingMinutes,
                AggregateLikes = r.AggregateLikes,
                VeryPopular = r.VeryPopular,
                RecipeIngredients = r.RecipeIngredients.Select(ri => new RecipeIngredientDto
                {
                    IngredientId = ri.IngredientId,
                    Amount = ri.Amount,
                    Unit = ri.Unit,
                    IsMajor = ri.IsMajor,
                    OriginalText = ri.OriginalText,
                    
                }).ToList(),
                RecipeCuisines = r.RecipeCuisines.Select(rc => rc.Cuisine.Name).ToList(), //list of cuisine names
                RecipeDishTypes = r.RecipeDishTypes.Select(rd => rd.DishType.Name).ToList(), //list of dish type names
            };
        }
        public async Task<IEnumerable<RecipeRecommendationDto>> GetRecommendedRecipes(string userId, double matchPercentCutoff)
        {
            var recommendations = await _context.RecipeRecommendations
                .FromSqlRaw("EXEC GetRecommendedRecipes_MatchAll @UserId, @MatchPercentCutoff",
                    new SqlParameter("@UserId", userId),
                    new SqlParameter("@MatchPercentCutoff", matchPercentCutoff))
                .ToListAsync();
            
            // var imageHostingUrl = "http://localhost:5169/images"; // Replace with your actual image hosting URL
            var imageHostingUrl = "https://192.168.1.162:5001/images"; // Replace with your actual image hosting URL

            return recommendations.Select(r => new RecipeRecommendationDto
            {
                RecipeId = r.RecipeId,
                Name = r.Name,
                ImageUrl = $"{imageHostingUrl}/{r.ImageUrl}",
                ReadyInMinutes = r.ReadyInMinutes,
                Servings = r.Servings,
                Vegetarian = r.Vegetarian,
                Vegan = r.Vegan,
                GlutenFree = r.GlutenFree,
                IngredientCount = r.IngredientCount,
                SourceUrl = r.SourceUrl,
                SourceName = r.SourceName,
                PreparationMinutes = r.PreparationMinutes,
                CookingMinutes = r.CookingMinutes,
                AggregateLikes = r.AggregateLikes,
                VeryPopular = r.VeryPopular,

            });
              
        }

        // TO-DO: Move this part to database cleanning and parsing.
        // Instructions are not in the same format and can't be separated the same way.
        // This is a temporary solution to parse the instructions.
        protected List<string> GetRecipeInstructions(string instructions)
        {
            // var list = instructions
            //     .Split(new[] { "                                                                                                " }, StringSplitOptions.RemoveEmptyEntries)
            //     .Select(instruction => instruction.Trim())
            //     .Where(instruction => !string.IsNullOrWhiteSpace(instruction))
            //     .ToList();
            
            // var list = Regex.Split(instructions, @"\s{5,}") // Split on 5+ whitespace chars
            //            .Select(s => s.Trim())
            //            .Where(s => !string.IsNullOrWhiteSpace(s))
            //            .ToList();

            var list = instructions
                .Split(new[] { '.' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim() + ".")
                .Where(s => s != ".")
                .ToList();

            return list;
        }
    }
}