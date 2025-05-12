USE [GroceryDB]
GO

/****** Object:  Table [dbo].[RecipeDishType]    Script Date: 5/6/2025 10:39:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RecipeDishType](
	[RecipeId] [varchar](20) NOT NULL,
	[DishTypeId] [varchar](20) NOT NULL,
 CONSTRAINT [PK_RecipeDishType] PRIMARY KEY CLUSTERED 
(
	[RecipeId] ASC,
	[DishTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RecipeDishType]  WITH CHECK ADD  CONSTRAINT [FK_RecipeDishType_DishType_DishTypeId] FOREIGN KEY([DishTypeId])
REFERENCES [dbo].[DishType] ([DishTypeId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeDishType] CHECK CONSTRAINT [FK_RecipeDishType_DishType_DishTypeId]
GO

ALTER TABLE [dbo].[RecipeDishType]  WITH CHECK ADD  CONSTRAINT [FK_RecipeDishType_Recipes_RecipeId] FOREIGN KEY([RecipeId])
REFERENCES [dbo].[Recipes] ([RecipeId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeDishType] CHECK CONSTRAINT [FK_RecipeDishType_Recipes_RecipeId]
GO


