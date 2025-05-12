using Xunit;
using Moq;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using GroceryApi.Data;
using GroceryApi.Models;
using GroceryApi.Services;

public class IngredientServiceTest
{
    [Fact]
    public async Task SyncIngredients_ShouldAddNewIngredients()
    {
        // Arrange
        var mockContext = new Mock<GroceryContext>();
        var mockLogger = new Mock<ILogger<IngredientService>>();
        var service = new IngredientService(mockContext.Object, mockLogger.Object);

        var userId = "test-user";
        var dto = new BatchIngredientsDto
        {
            Items = new List<BatchIngredientItem>
            {
                new BatchIngredientItem { Name = "Tomato" },
                new BatchIngredientItem { Name = "Onion" }
            }
        };

        // Act
        await service.SyncIngredients(userId, dto);

        // Assert
        // Verify that the context methods were called as expected
        mockContext.Verify(c => c.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}