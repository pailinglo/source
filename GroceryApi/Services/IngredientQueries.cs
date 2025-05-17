using GroceryApi.Data;
using Microsoft.EntityFrameworkCore;

namespace GroceryApi.Services
{
    public record IngredientResult(string IngredientId, string Name);

    // 2. Create a static class to hold compiled queries
    public static class IngredientQueries
    {
        private static Func<GroceryContext, List<string>, IEnumerable<IngredientResult>>? _directMatchesQuery;
        private static Func<GroceryContext, List<string>, IEnumerable<IngredientResult>>? _synonymMatchesQuery;
        private static Func<GroceryContext, List<string>, IEnumerable<IngredientResult>>? _reverseSynonymMatchesQuery;
        private static Func<GroceryContext, List<string>, IEnumerable<IngredientResult>>? _crossIngredientQuery;
        
        private static readonly object _lock = new();
        private static bool _initialized = false;

        public static void EnsureInitialized(IDbContextFactory<GroceryContext> contextFactory)
        {
            if (_initialized) return;
            
            lock (_lock)
            {
                if (_initialized) return;
                
                using var context = contextFactory.CreateDbContext();
                
                _directMatchesQuery = EF.CompileQuery((GroceryContext ctx, List<string> terms) =>
                    from i in ctx.Ingredients.AsNoTracking()
                    join n in ctx.IngredientName.AsNoTracking() on i.IngredientId equals n.IngredientId
                    where terms.Contains(i.Name.ToLower()) || 
                          terms.Contains(n.Curated.ToLower()) ||
                          terms.Contains(n.Extended.ToLower())
                    select new IngredientResult(i.IngredientId, i.Name));

                // Synonym matches (name → synonym)
                _synonymMatchesQuery = EF.CompileQuery((GroceryContext ctx, List<string> terms) =>
                    from i in ctx.Ingredients.AsNoTracking()
                    join n in ctx.IngredientName.AsNoTracking() on i.IngredientId equals n.IngredientId
                    join s in ctx.IngredientSynonym.AsNoTracking() on n.Curated equals s.Name
                    where terms.Contains(s.Synonym.ToLower()) &&
                          (s.LLMReportOrder <= 3 || s.IsMisspelling)
                    select new IngredientResult(i.IngredientId, i.Name));

                // Reverse synonym matches (synonym → name)
                _reverseSynonymMatchesQuery = EF.CompileQuery((GroceryContext ctx, List<string> terms) =>
                    from i in ctx.Ingredients.AsNoTracking()
                    join n in ctx.IngredientName.AsNoTracking() on i.IngredientId equals n.IngredientId
                    join s in ctx.IngredientSynonym.AsNoTracking() on n.Curated equals s.Synonym
                    where terms.Contains(s.Name.ToLower()) &&
                          (s.LLMReportOrder <= 3 || s.IsMisspelling)
                    select new IngredientResult(i.IngredientId, i.Name));


                _crossIngredientQuery = EF.CompileQuery((GroceryContext ctx, List<string> terms) =>
                    from n1 in ctx.IngredientName.AsNoTracking()
                    join n2 in ctx.IngredientName.AsNoTracking() on n1.Curated equals n2.Curated
                    where terms.Contains(n1.Curated.ToLower()) ||
                          terms.Contains(n1.OriginalName.ToLower())
                    select new IngredientResult(n2.IngredientId, n2.OriginalName));

                _initialized = true;
            }
        }

        public static IEnumerable<IngredientResult> GetDirectMatches(GroceryContext context, List<string> searchTerms)
            => _directMatchesQuery?.Invoke(context, searchTerms) ?? Enumerable.Empty<IngredientResult>();

        public static IEnumerable<IngredientResult> GetSynonymMatches(GroceryContext context, List<string> searchTerms)
            => _synonymMatchesQuery?.Invoke(context, searchTerms) ?? Enumerable.Empty<IngredientResult>();

        public static IEnumerable<IngredientResult> GetReverseSynonymMatches(GroceryContext context, List<string> searchTerms)
            => _reverseSynonymMatchesQuery?.Invoke(context, searchTerms) ?? Enumerable.Empty<IngredientResult>();

        public static IEnumerable<IngredientResult> GetCrossIngredientMatches(GroceryContext context, List<string> searchTerms)
            => _crossIngredientQuery?.Invoke(context, searchTerms) ?? Enumerable.Empty<IngredientResult>();
    }
}