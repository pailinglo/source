-- Reset GroceryDB --
use GroceryDB
-- clean all ingredients and User ingredients
begin transaction

Delete from RecipeIngredients
Delete from RecipeCuisine
Delete from RecipeDishType
Delete from Recipes
Delete from Cuisine
Delete from DishType
--Delete from UserIngredients
--Delete from IngredientName
--Delete from Ingredients

commit transaction


--These are not needed, because when building the Ingredients table, all the recipes are considered. no filtering
--In that sense, only recipe related tables need to be considered.

