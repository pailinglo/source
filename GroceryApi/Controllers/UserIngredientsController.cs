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

        // TODO: Move code to a service class for better separation of concerns
        [HttpPost("batch")]
        public async Task<IActionResult> SyncIngredients(string userId, [FromBody] BatchIngredientsDto dto)
        {
            if (_context == null)
            {
                return Problem("Database context is not available.");
            }

            // Log the content of the FromBody parameter
            _logger.LogDebug("Received BatchIngredientsDto: {BatchIngredients}", System.Text.Json.JsonSerializer.Serialize(dto));

            // Get existing UserIngredients from the database
            var existingUserIngredients = await _context.UserIngredients
                .Where(ui => ui.UserId == userId)
                .Include(ui => ui.Ingredient) // Eagerly load to include the Ingredient navigation property
                .ToListAsync();

            // Get unique items by name (case-insensitive)
            // This will remove duplicates based on the name property and avoid adding record errors.
            var uniqueItems = dto.Items
                .GroupBy(item => item.Name.ToLower())
                .Select(group => group.First())
                .ToList();

            // Get existing ingredients from the database that match the unique items by name
            // var ingredients = await _context.Ingredients
            //     .Where(i => uniqueItems.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()))
            //     .ToListAsync();

            // Use a join to get the ingredients that match the unique items by name or processed name
            var ingredients = await (from i in _context.Ingredients
                         join iname in _context.IngredientName
                         on i.IngredientId equals iname.IngredientId
                         where uniqueItems.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()) || 
                               uniqueItems.Select(x => x.Name.ToLower()).Contains(iname.Processed.ToLower())
                         select i)
                         .Include(i => i.IngredientName) // Eagerly load to include the UserIngredients navigation property
                         .ToListAsync();

            // Determine items to remove
            // Remove items from the existingUserIngredients that are not in the uniqueItemNames list
            var uniqueItemNames = uniqueItems
                .Select(item => item.Name.ToLower())
                .ToList();
            
            var itemsToRemove = existingUserIngredients
                .Where(ui => ui.Ingredient != null && !uniqueItemNames.Contains(ui.Ingredient.Name.ToLower()))
                .ToList();

            // Remove items
            if (itemsToRemove.Any())
            {
                _context.UserIngredients.RemoveRange(itemsToRemove);
            }

            var newUserIngredients = new List<UserIngredient>();
            foreach (var item in uniqueItems)
            {
                var ingredient = ingredients.FirstOrDefault(i => i.Name.ToLower() == item.Name.ToLower() || i.IngredientName.Processed.ToLower() == item.Name.ToLower());
                if (ingredient == null)
                {
                    continue; // Skip if ingredient is not found in the database
                    
                    // TODO: I should map the unseen ingredient to our existing ingredient list
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