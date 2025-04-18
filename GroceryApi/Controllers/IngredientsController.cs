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
        public async Task<ActionResult<IEnumerable<Ingredient>>> GetIngredients([FromQuery] string? name = null)
        {
            var query = _context.Ingredients.AsQueryable();
            if (!string.IsNullOrEmpty(name))
            {
                query = query.Where(i => i.Name.Contains(name));
            }
            return await query.ToListAsync();
        }
    }
}