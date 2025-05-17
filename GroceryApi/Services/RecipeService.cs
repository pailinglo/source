using System.Text.RegularExpressions;
using GroceryApi.Data;
using GroceryApi.Models;
using GroceryApi.Configuration;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace GroceryApi.Services
{
    public class RecipeService
    {
        private readonly IDbContextFactory<GroceryContext> _contextFactory;
        private readonly MatchSettings _matchSettings;
        private readonly ILogger<RecipeService> _logger;
        private readonly IConfiguration _configuration;
        public RecipeService(IDbContextFactory<GroceryContext> contextFactory, 
            IOptions<MatchSettings> matchSettings, 
            ILogger<RecipeService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _contextFactory = contextFactory;    
            _matchSettings = matchSettings.Value; // Access the MatchSettings value
            _configuration = configuration; // Access the configuration
        }
        
        public async Task<RecipeDto?> GetRecipe(string recipeId)
        {
            await using var context = await _contextFactory.CreateDbContextAsync();
        
            var r = await context.Recipes
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

            var imageHostingUrl = "https://192.168.1.162:5001/images"; // Replace with your actual image hosting URL

             return new RecipeDto
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
        public async Task<IEnumerable<RecipeRecommendationDto>> GetRecommendedRecipes(string userId)
        {
            await using var context = await _contextFactory.CreateDbContextAsync();
        
             // Use the configured value from appsettings.json
            string matchStoreProcedure = _matchSettings.MatchType switch
            {
                GroceryApi.Configuration.MatchType.MatchAll => "GetRecommendedRecipes_MatchAll",
                GroceryApi.Configuration.MatchType.MatchMajor => "GetRecommendedRecipes_MatchMajor",
                GroceryApi.Configuration.MatchType.MatchBoth => "GetRecommendedRecipes_MatchBoth",
                _ => throw new ArgumentOutOfRangeException()
            };
            

            List<RecipeRecommendation> recommendations;

            _logger.LogInformation($"SP: {matchStoreProcedure} Cutoff:{_matchSettings.MatchPercentCutoff} MajorCutoff:{_matchSettings.MatchMajorPercentCutoff}");
                
            if(_matchSettings.MatchType == GroceryApi.Configuration.MatchType.MatchMajor ||
               _matchSettings.MatchType == GroceryApi.Configuration.MatchType.MatchAll)
            {
                double matchPercentCutoff = _matchSettings.MatchPercentCutoff;
                recommendations = await context.RecipeRecommendations
                    .FromSqlInterpolated($"EXEC {matchStoreProcedure} {userId}, {matchPercentCutoff}")
                    .ToListAsync();
            }
            else
            {
                double Cutoff_All = _matchSettings.MatchPercentCutoff;
                double Cutoff_Major = _matchSettings.MatchMajorPercentCutoff;
                recommendations = await context.RecipeRecommendations
                    .FromSqlInterpolated($"EXEC {matchStoreProcedure} {userId}, {Cutoff_All}, {Cutoff_Major}")
                    .ToListAsync();
            }
            
            var imageHostingUrl = _configuration.GetValue<string>("ImageHost:BaseUrl"); //"https://192.168.1.162:5001/images"; // Replace with your actual image hosting URL

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