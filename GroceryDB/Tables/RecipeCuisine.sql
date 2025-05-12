USE [GroceryDB]
GO

/****** Object:  Table [dbo].[RecipeCuisine]    Script Date: 5/6/2025 10:39:32 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RecipeCuisine](
	[RecipeId] [varchar](20) NOT NULL,
	[CuisineId] [varchar](20) NOT NULL,
 CONSTRAINT [PK_RecipeCuisine] PRIMARY KEY CLUSTERED 
(
	[RecipeId] ASC,
	[CuisineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RecipeCuisine]  WITH CHECK ADD  CONSTRAINT [FK_RecipeCuisine_Cuisine_CuisineId] FOREIGN KEY([CuisineId])
REFERENCES [dbo].[Cuisine] ([CuisineId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeCuisine] CHECK CONSTRAINT [FK_RecipeCuisine_Cuisine_CuisineId]
GO

ALTER TABLE [dbo].[RecipeCuisine]  WITH CHECK ADD  CONSTRAINT [FK_RecipeCuisine_Recipes_RecipeId] FOREIGN KEY([RecipeId])
REFERENCES [dbo].[Recipes] ([RecipeId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeCuisine] CHECK CONSTRAINT [FK_RecipeCuisine_Recipes_RecipeId]
GO


