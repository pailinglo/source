using GroceryApi.Data;
using GroceryApi.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Humanizer;


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
            // First create the singularized items
            var itemsWithSingularNames = dto.Items
                .Select(item => new 
                { 
                    OriginalName = item.Name, 
                    SingularName = item.Name?.Singularize(inputIsKnownToBePlural: false) ?? item.Name 
                })
                .ToList();

            // Then get distinct by singular name (case-insensitive)
            var uniqueItems = itemsWithSingularNames
                .GroupBy(item => item.SingularName?.ToLower() ?? item.OriginalName.ToLower())
                .Select(group => group.First())
                .ToList();

            // Fuzzy matching to ingredients from the database
            var ingredients = await (
                from i in _context.Ingredients
                join n in _context.IngredientName on i.IngredientId equals n.IngredientId
                where uniqueItems.Select(x => x.SingularName.ToLower()).Contains(i.Name.ToLower()) || 
                    uniqueItems.Select(x => x.SingularName.ToLower()).Contains(n.Curated.ToLower())
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
                uniqueItems.Select(x => x.SingularName.ToLower()).Contains(syn.Synonym.ToLower())
                select new
                {
                    i.IngredientId,
                    i.Name
                }
            )
            .Union(
                from i in _context.Ingredients
                join n in _context.IngredientName on i.IngredientId equals n.IngredientId
                join n2 in _context.IngredientName on n.Curated equals n2.Curated
                where 
                (uniqueItems.Select(x => x.SingularName.ToLower()).Contains(n2.Curated.ToLower()) ||
                 uniqueItems.Select(x => x.SingularName.ToLower()).Contains(i.Name.ToLower()))
                select new
                {
                    IngredientId = n2.IngredientId,
                    Name = n2.OriginalName
                    // i.IngredientId,
                    // i.Name
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
                _logger.LogInformation($"Added UserIngredient for user {userId}: {ingredient.Name}");
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