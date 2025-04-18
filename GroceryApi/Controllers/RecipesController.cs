using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;
using Microsoft.Data.SqlClient;

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
            var recommendations = await _context.RecipeRecommendations
                .FromSqlRaw("EXEC GetRecommendedRecipes @UserId", new SqlParameter("@UserId", userId))
                .ToListAsync();
            return Ok(recommendations ?? new List<RecipeRecommendation>());
        }
    }
}