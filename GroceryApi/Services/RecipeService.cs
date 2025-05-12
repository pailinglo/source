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

        public async Task<Recipe> GetRecipe(string recipeId)
        {
            return await _context.Recipes
                .Include(r => r.RecipeIngredients)
                .ThenInclude(ri => ri.Ingredient)
                .FirstOrDefaultAsync(r => r.RecipeId == recipeId);
        }
        public async Task<IEnumerable<RecipeRecommendationDto>> GetRecommendedRecipes(string userId, double matchPercentCutoff)
        {
            var recommendations = await _context.RecipeRecommendations
                .FromSqlRaw("EXEC GetRecommendedRecipes_MatchAll @UserId, @MatchPercentCutoff",
                    new SqlParameter("@UserId", userId),
                    new SqlParameter("@MatchPercentCutoff", matchPercentCutoff))
                .ToListAsync();
            
            var imageHostingUrl = "http://localhost:5169/images"; // Replace with your actual image hosting URL
            foreach (var recommendation in recommendations)
            {
                recommendation.ImageUrl = $"{imageHostingUrl}/{recommendation.ImageUrl}";
            }  

            return recommendations.Select(r => new RecipeRecommendationDto
            {
                RecipeId = r.RecipeId,
                Name = r.Name,
                Instructions = GetRecipeInstructions(r.Instructions),
                ImageUrl = $"{imageHostingUrl}/{r.ImageUrl}",
                ReadyInMinutes = r.ReadyInMinutes,
                Servings = r.Servings,
                Vegetarian = r.Vegetarian,
                Vegan = r.Vegan,
                GlutenFree = r.GlutenFree,
                MatchCount = r.MatchCount,
                MatchPercent = r.MatchPercent,
                MajorIngredientCount = r.MajorIngredientCount,
                MatchMajorCount = r.MatchMajorCount,
                MatchMajorPercent = r.MatchMajorPercent,
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