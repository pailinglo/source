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
        // private readonly GroceryContext _context;
        private readonly IDbContextFactory<GroceryContext> _contextFactory;

        private readonly ILogger<IngredientService> _logger;

        public IngredientService(
            IDbContextFactory<GroceryContext> contextFactory, 
            ILogger<IngredientService> logger)
        {
             _contextFactory = contextFactory;
            _logger = logger;
        
            // Initialize compiled queries on first use
            IngredientQueries.EnsureInitialized(contextFactory);
        }

        public async Task SyncIngredients(string userId, BatchIngredientsDto dto)
        {
            await using var context = await _contextFactory.CreateDbContextAsync();
        
            if (context == null)
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
            // First materialize the search terms locally
            var searchTerms = uniqueItems.Select(x => x.SingularName.ToLower()).ToList();
            
            var ingredients = await SearchIngredients(searchTerms);
            _logger.LogInformation("Found ingredients: {Ingredients}", System.Text.Json.JsonSerializer.Serialize(ingredients));
            
            var newUserIngredients = new List<UserIngredient>();
            
            foreach(var ingredient in ingredients){
                newUserIngredients.Add(new UserIngredient
                {
                    UserId = userId,
                    IngredientId = ingredient.IngredientId
                });
                _logger.LogInformation($"Added UserIngredient for user {userId}: {ingredient.Name}");
            }

            using var transaction = await context.Database.BeginTransactionAsync(); // Start a transaction

            // Delete existing user ingredients for the user
            await context.Database.ExecuteSqlRawAsync("DELETE FROM UserIngredients WHERE UserId = {0}", userId);

            if (newUserIngredients.Any())
            {
                context.UserIngredients.AddRange(newUserIngredients);
            }

            await context.SaveChangesAsync();
            await transaction.CommitAsync(); // Commit the transaction
    
        }

        public async Task<List<IngredientResult>> SearchIngredients(List<string> searchTerms)
        {
            // Create new context instance for this operation
            //using var context = new GroceryContext(_contextOptions);
            await using var context = await _contextFactory.CreateDbContextAsync();
        
            
            // Execute queries in parallel - synchronous need separate context otherwise will encounter error:
            // An attempt was made to use the context instance while it is being configured. A DbContext instance cannot be used inside 'OnConfiguring' since it is still being configured at this point. 
            // var directTask = Task.Run(() => IngredientQueries.GetDirectMatches(context, searchTerms).ToList());
            // var synonymTask = Task.Run(() => IngredientQueries.GetSynonymMatches(context, searchTerms).ToList());
            // var crossTask = Task.Run(() => IngredientQueries.GetCrossIngredientMatches(context, searchTerms).ToList());
            
            var directMatches  = IngredientQueries.GetDirectMatches(context, searchTerms).ToList();
            var synonymMatches  = IngredientQueries.GetSynonymMatches(context, searchTerms).ToList();
            var reverseSynonymMatches  = IngredientQueries.GetReverseSynonymMatches(context, searchTerms).ToList();
            var crossMatches  = IngredientQueries.GetCrossIngredientMatches(context, searchTerms).ToList();
            

            // await Task.WhenAll(directTask, synonymTask, crossTask);
            
            // Combine results
            // return directTask.Result
            //     .Union(synonymTask.Result)
            //     .Union(crossTask.Result)
            //     .ToList();

            return directMatches
            .Union(synonymMatches)
            .Union(reverseSynonymMatches)
            .Union(crossMatches)
            .ToList();
        }
        
        
    }
}