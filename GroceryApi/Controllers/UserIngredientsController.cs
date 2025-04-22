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
        private readonly ILogger<UserIngredientsController> _logger;

        private readonly GroceryContext? _context;

        public UserIngredientsController(GroceryContext context, ILogger<UserIngredientsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost("batch")]
        public async Task<IActionResult> AddIngredients(string userId, [FromBody] BatchIngredientsDto dto)
        {
            if (_context == null)
            {
                return Problem("Database context is not available.");
            }

            // Log the content of the FromBody parameter
            _logger.LogDebug("Received BatchIngredientsDto: {BatchIngredients}", System.Text.Json.JsonSerializer.Serialize(dto));

            // Get unique items by name (case-insensitive)
            // This will remove duplicates based on the name property and avoid adding record errors.
            var uniqueItems = dto.Items
                .GroupBy(item => item.Name.ToLower())
                .Select(group => group.First())
                .ToList();

            // Get existing ingredients from the database
            var ingredients = await _context.Ingredients
                .Where(i => uniqueItems.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()))
                .ToListAsync();

            // Get existing UserIngredients from the database
            var existingUserIngredients = await _context.UserIngredients
                .Where(ui => ui.UserId == userId)
                .ToListAsync();

            var newUserIngredients = new List<UserIngredient>();
            foreach (var item in uniqueItems)
            {
                var ingredient = ingredients.FirstOrDefault(i => i.Name.ToLower() == item.Name.ToLower());
                if (ingredient == null)
                {
                    ingredient = new Ingredient
                    {
                        IngredientId = $"ing-{item.Name.ToLower().Replace(' ', '-')}",
                        Name = item.Name
                    };
                    // Check if the ingredient is already being tracked
                    // since ingredients are existing list in the database before adding the ingredient
                    if (!_context.ChangeTracker.Entries<Ingredient>().Any(e => e.Entity.Name.ToLower() == ingredient.Name.ToLower()))
                    {
                        _context.Ingredients.Add(ingredient);
                        _logger.LogDebug($"Added new ingredient: {ingredient.Name}");
                    
                    }
                }

                // Check if the UserIngredient already exists
                if (!existingUserIngredients.Any(ui => ui.IngredientId == ingredient.IngredientId))
                {
                    newUserIngredients.Add(new UserIngredient
                    {
                        UserId = userId,
                        IngredientId = ingredient.IngredientId
                    });
                        // Log the ingredient being added
                    _logger.LogDebug($"Added UserIngredient for user {userId}: {ingredient.Name}");
            
                }
            
            }

            // Add only new UserIngredients
            if (newUserIngredients.Any())
            {
                _context.UserIngredients.AddRange(newUserIngredients);
            }
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}