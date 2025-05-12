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

            
            // Get unique items by name (case-insensitive)
            var uniqueItems = dto.Items
                .GroupBy(item => item.Name.ToLower())
                .Select(group => group.First())
                .ToList();

            // Fuzzy matching to ingredients from the database
            var ingredients = await (
                from i in _context.Ingredients
                join n in _context.IngredientName on i.IngredientId equals n.IngredientId
                where uniqueItems.Select(x => x.Name.ToLower()).Contains(i.Name.ToLower()) || 
                    uniqueItems.Select(x => x.Name.ToLower()).Contains(n.Curated.ToLower())
                select new
                {
                    i.IngredientId,
                    i.Name
                }
            )
            .Union(
                from i in _context.Ingredients
                join n in _context.IngredientName on i.IngredientId equals n.IngredientId
                join syn in _context.IngredientSynonym on n.Curated equals syn.Name 
                where 
                (syn.LLMReportOrder <= 3 || syn.IsMisspelling) &&
                uniqueItems.Select(x => x.Name.ToLower()).Contains(syn.Synonym.ToLower())
                select new
                {
                    i.IngredientId,
                    i.Name
                }
            )
            .ToListAsync();

            var newUserIngredients = new List<UserIngredient>();
            
            foreach(var ingredient in ingredients){
                newUserIngredients.Add(new UserIngredient
                {
                    UserId = userId,
                    IngredientId = ingredient.IngredientId
                });
                _logger.LogDebug($"Added UserIngredient for user {userId}: {ingredient.Name}");
            }

            using var transaction = await _context.Database.BeginTransactionAsync(); // Start a transaction

            // Delete existing user ingredients for the user
            await _context.Database.ExecuteSqlRawAsync("DELETE FROM UserIngredients WHERE UserId = {0}", userId);

            if (newUserIngredients.Any())
            {
                _context.UserIngredients.AddRange(newUserIngredients);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync(); // Commit the transaction
    
        }
    }
}