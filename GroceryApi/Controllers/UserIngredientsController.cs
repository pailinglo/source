using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;

namespace GroceryApi.Controllers
{
    [Route("api/users/{userId}/ingredients")]
    [ApiController]
    public class UserIngredientsController : ControllerBase
    {
        private readonly GroceryContext _context;

        public UserIngredientsController(GroceryContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Ingredient>>> GetUserIngredients(string userId)
        {
            return await _context.UserIngredients
                .Where(ui => ui.UserId == userId)
                .Include(ui => ui.Ingredient)
                .Select(ui => ui.Ingredient)
                .ToListAsync();
        }

        [HttpPost]
        public async Task<ActionResult<UserIngredient>> AddUserIngredient(string userId, [FromBody] UserIngredientDto dto)
        {
            var userIngredient = new UserIngredient
            {
                UserId = userId,
                IngredientId = dto.IngredientId
            };
            _context.UserIngredients.Add(userIngredient);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetUserIngredients), new { userId }, userIngredient);
        }

        [HttpDelete("{ingredientId}")]
        public async Task<IActionResult> DeleteUserIngredient(string userId, string ingredientId)
        {
            var userIngredient = await _context.UserIngredients
                .FirstOrDefaultAsync(ui => ui.UserId == userId && ui.IngredientId == ingredientId);
            if (userIngredient == null) return NotFound();
            _context.UserIngredients.Remove(userIngredient);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }

    public class UserIngredientDto
    {
        public string IngredientId { get; set; }
    }
}