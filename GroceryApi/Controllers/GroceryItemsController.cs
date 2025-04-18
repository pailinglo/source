using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;

namespace GroceryApi.Controllers
{
    [Route("api/users/{userId}/items")]
    [ApiController]
    public class GroceryItemsController : ControllerBase
    {
        private readonly GroceryContext _context;

        public GroceryItemsController(GroceryContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<GroceryItem>>> GetGroceryItems(string userId)
        {
            return await _context.GroceryItems
                .Where(g => g.UserId == userId)
                .ToListAsync();
        }

        [HttpGet("{itemId}")]
        public async Task<ActionResult<GroceryItem>> GetGroceryItem(string userId, string itemId)
        {
            var item = await _context.GroceryItems
                .FirstOrDefaultAsync(g => g.UserId == userId && g.ItemId == itemId);
            if (item == null) return NotFound();
            return item;
        }

        [HttpPost]
        public async Task<ActionResult<GroceryItem>> AddGroceryItem(string userId, [FromBody] GroceryItem item)
        {
            item.ItemId = Guid.NewGuid().ToString();
            item.UserId = userId;
            _context.GroceryItems.Add(item);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetGroceryItem), new { userId, itemId = item.ItemId }, item);
        }

        [HttpPut("{itemId}")]
        public async Task<IActionResult> UpdateGroceryItem(string userId, string itemId, [FromBody] GroceryItem item)
        {
            if (itemId != item.ItemId || userId != item.UserId) return BadRequest();
            var existingItem = await _context.GroceryItems.FindAsync(itemId);
            if (existingItem == null) return NotFound();
            existingItem.Name = item.Name;
            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{itemId}")]
        public async Task<IActionResult> DeleteGroceryItem(string userId, string itemId)
        {
            var item = await _context.GroceryItems
                .FirstOrDefaultAsync(g => g.UserId == userId && g.ItemId == itemId);
            if (item == null) return NotFound();
            _context.GroceryItems.Remove(item);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}