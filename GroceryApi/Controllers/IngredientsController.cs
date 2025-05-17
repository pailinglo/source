using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;

namespace GroceryApi.Controllers
{
    [Route("api/ingredients")]
    [ApiController]
    public class IngredientsController : ControllerBase
    {
        private readonly IDbContextFactory<GroceryContext> _contextFactory;

        public IngredientsController(IDbContextFactory<GroceryContext> contextFactory)
        {
            _contextFactory = contextFactory;
        }
        
        [HttpGet]
        public async Task<ActionResult<IEnumerable<IngredientDto>>> GetIngredients()
        {
            await using var _context = await _contextFactory.CreateDbContextAsync();
        
            var ingredients = await _context.Ingredients
                .Select(i => new IngredientDto
                {
                    IngredientId = i.IngredientId,
                    Name = i.Name
                })
                .ToListAsync();
            return Ok(ingredients);
        }
    }
}