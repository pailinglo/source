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
        private readonly GroceryContext _context;

        public IngredientsController(GroceryContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<IngredientDto>>> GetIngredients()
        {
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