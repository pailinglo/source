using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;

namespace GroceryApi.Controllers
{
    [Route("api/recipes")]
    [ApiController]
    public class RecipesController : ControllerBase
    {
        private readonly GroceryContext _context;

        public RecipesController(GroceryContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Recipe>>> GetRecipes()
        {
            return await _context.Recipes
                .Include(r => r.RecipeIngredients)
                .ThenInclude(ri => ri.Ingredient)
                .ToListAsync();
        }

        [HttpGet("{recipeId}")]
        public async Task<ActionResult<Recipe>> GetRecipe(string recipeId)
        {
            var recipe = await _context.Recipes
                .Include(r => r.RecipeIngredients)
                .ThenInclude(ri => ri.Ingredient)
                .FirstOrDefaultAsync(r => r.RecipeId == recipeId);
            if (recipe == null) return NotFound();
            return recipe;
        }

        [HttpGet("recommend/{userId}")]
        public async Task<ActionResult<IEnumerable<RecipeRecommendation>>> GetRecommendedRecipes(string userId)
        {
            var userIngredientIds = await _context.UserIngredients
                .Where(ui => ui.UserId == userId)
                .Select(ui => ui.IngredientId)
                .ToListAsync();

            var recommendations = await _context.Recipes
                .Join(_context.RecipeIngredients,
                    r => r.RecipeId,
                    ri => ri.RecipeId,
                    (r, ri) => new { r, ri })
                .Where(x => userIngredientIds.Contains(x.ri.IngredientId))
                .GroupBy(x => new { x.r.RecipeId, x.r.Name, x.r.IngredientCount })
                .Select(g => new RecipeRecommendation
                {
                    RecipeId = g.Key.RecipeId,
                    Name = g.Key.Name,
                    MatchCount = g.Count(),
                    MatchPercent = (double)g.Count() / g.Key.IngredientCount
                })
                .Where(r => r.MatchPercent >= 0.7)
                .OrderByDescending(r => r.MatchCount)
                .ToListAsync();

            return recommendations;
        }
    }
}