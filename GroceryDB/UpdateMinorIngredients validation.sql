
-- execute store procedure --

exec [dbo].[UpdateMinorIngredients]

-- Verification --

Select count(1) from RecipeIngredients where IsMajor = 1
Select count(1) from RecipeIngredients where IsMajor = 0

-- expected result : 0
select ri.RecipeId, ri.IngredientId,ri.OriginalText,n.OriginalName, n.Curated from RecipeIngredients ri
inner join IngredientName n on ri.IngredientId = n.IngredientId
inner join MinorIngredients minor on minor.ingredient_name = n.curated
where ri.IsMajor = 1
union
select ri.RecipeId, ri.IngredientId,ri.OriginalText,n.OriginalName, n.Curated from RecipeIngredients ri
inner join IngredientName n on ri.IngredientId = n.IngredientId
inner join IngredientSynonyms syn on syn.Name = n.Curated
inner join MinorIngredients minor on minor.ingredient_name = syn.Synonym and syn.LLMReportOrder <=3
where ri.IsMajor = 1