using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Models;
using GroceryApi.Services;
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

        private readonly IDbContextFactory<GroceryContext> _contextFactory;
        private readonly IngredientService _ingredientService;


        public UserIngredientsController(IDbContextFactory<GroceryContext> contextFactory, 
            ILogger<UserIngredientsController> logger,
            IngredientService ingredientService)
        {
            _contextFactory = contextFactory;
            _logger = logger;
            _ingredientService = ingredientService;
        }

        [HttpPost("batch")]
        public async Task<IActionResult> SyncIngredients(string userId, [FromBody] BatchIngredientsDto dto)
        {
            try
            {
                await _ingredientService.SyncIngredients(userId, dto);
                return Ok();
            }
            catch (System.Exception ex)
            {
                return Problem(ex.Message);
            }
        }
    }
}