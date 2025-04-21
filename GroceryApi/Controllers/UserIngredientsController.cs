using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace GroceryApi.Controllers
{
    [Route("api/users/{userId}/ingredients")]
    [ApiController]
    public class UserIngredientsController : ControllerBase
    {
        private readonly GroceryContext? _context;

        public UserIngredientsController(GroceryContext context)
        {
            _context = context;
        }

        [HttpPost("batch")]
        public async Task<IActionResult> AddIngredients(string userId, [FromBody] BatchIngredientsDto dto)
        {
            if (_context == null)
            {
                return Problem("Database context is not available.");
            }

            var ingredients = await _context.Ingredients
                .Where(i => dto.Items.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()))
                .ToListAsync();

            var newUserIngredients = new List<UserIngredient>();
            foreach (var item in dto.Items)
            {
                var ingredient = ingredients.FirstOrDefault(i => i.Name.ToLower() == item.Name.ToLower());
                if (ingredient == null)
                {
                    ingredient = new Ingredient
                    {
                        IngredientId = $"ing-{item.Name.ToLower().Replace(' ', '-')}",
                        Name = item.Name
                    };
                    _context.Ingredients.Add(ingredient);
                }

                newUserIngredients.Add(new UserIngredient
                {
                    UserId = userId,
                    IngredientId = ingredient.IngredientId
                });
            }

            _context.UserIngredients.AddRange(newUserIngredients);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}