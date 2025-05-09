using GroceryApi.Data;
using GroceryApi.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace GroceryApi.Services
{
    public class IngredientService
    {
        private readonly GroceryContext _context;
        private readonly ILogger<IngredientService> _logger;

        public IngredientService(GroceryContext context, ILogger<IngredientService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SyncIngredients(string userId, BatchIngredientsDto dto)
        {
            if (_context == null)
            {
                throw new System.Exception("Database context is not available.");
            }

            _logger.LogDebug("Received BatchIngredientsDto: {BatchIngredients}", System.Text.Json.JsonSerializer.Serialize(dto));

            // Get existing UserIngredients
            var existingUserIngredients = await _context.UserIngredients
                .Where(ui => ui.UserId == userId)
                .Include(ui => ui.Ingredient)
                .ToListAsync();

            // Get unique items by name (case-insensitive)
            var uniqueItems = dto.Items
                .GroupBy(item => item.Name.ToLower())
                .Select(group => group.First())
                .ToList();

            // Get existing ingredients from the database
            var ingredients = await (from i in _context.Ingredients
                                      join iname in _context.IngredientName
                                      on i.IngredientId equals iname.IngredientId
                                      where uniqueItems.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()) ||
                                            uniqueItems.Select(x => x.Name.ToLower()).Contains(iname.Processed.ToLower())
                                      select i)
                                      .Include(i => i.IngredientName)
                                      .ToListAsync();

            // Determine items to remove
            var uniqueItemNames = uniqueItems.Select(item => item.Name.ToLower()).ToList();
            var itemsToRemove = existingUserIngredients
                .Where(ui => ui.Ingredient != null && !uniqueItemNames.Contains(ui.Ingredient.Name.ToLower()))
                .ToList();

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

                if (!existingUserIngredients.Any(ui => ui.IngredientId == ingredient.IngredientId))
                {
                    newUserIngredients.Add(new UserIngredient
                    {
                        UserId = userId,
                        IngredientId = ingredient.IngredientId
                    });
                    _logger.LogDebug($"Added UserIngredient for user {userId}: {ingredient.Name}");
                }
            }

            if (newUserIngredients.Any())
            {
                _context.UserIngredients.AddRange(newUserIngredients);
            }

            await _context.SaveChangesAsync();
        }
    }
}