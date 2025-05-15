using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;
using GroceryApi.Services;
using Microsoft.Data.SqlClient;

namespace GroceryApi.Controllers
{
    [Route("api/recipes")]
    [ApiController]
    public class RecipesController : ControllerBase
    {
        private readonly GroceryContext _context;
        private readonly RecipeService _recipeService;

        public RecipesController(GroceryContext context, RecipeService recipeService)
        {
            _recipeService = recipeService;
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
        public async Task<ActionResult<RecipeDto>> GetRecipe(string recipeId)
        {
            var recipe = await _recipeService.GetRecipe(recipeId);
            if (recipe == null) return NotFound();
            return recipe;
        }

        [HttpGet("recommend/{userId}")]
        public async Task<ActionResult<IEnumerable<RecipeRecommendationDto>>> GetRecommendedRecipes(string userId)
        {
            var recommendations = await _recipeService.GetRecommendedRecipes(userId);
            
            return Ok(recommendations ?? new List<RecipeRecommendationDto>());
        }
    }
}