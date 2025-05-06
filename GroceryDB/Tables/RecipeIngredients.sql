USE [GroceryDB]
GO

/****** Object:  Table [dbo].[RecipeIngredients]    Script Date: 5/6/2025 10:40:17 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RecipeIngredients](
	[RecipeId] [varchar](20) NOT NULL,
	[IngredientId] [varchar](20) NOT NULL,
	[IsMajor] [bit] NOT NULL,
	[OriginalText] [nvarchar](255) NOT NULL,
	[Amount] [decimal](10, 2) NOT NULL,
	[Unit] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_RecipeIngredients] PRIMARY KEY CLUSTERED 
(
	[RecipeId] ASC,
	[IngredientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RecipeIngredients] ADD  DEFAULT (CONVERT([bit],(1))) FOR [IsMajor]
GO

ALTER TABLE [dbo].[RecipeIngredients] ADD  DEFAULT (N'') FOR [OriginalText]
GO

ALTER TABLE [dbo].[RecipeIngredients] ADD  DEFAULT ((0.0)) FOR [Amount]
GO

ALTER TABLE [dbo].[RecipeIngredients] ADD  DEFAULT (N'') FOR [Unit]
GO

ALTER TABLE [dbo].[RecipeIngredients]  WITH CHECK ADD  CONSTRAINT [FK_RecipeIngredients_Ingredients_IngredientId] FOREIGN KEY([IngredientId])
REFERENCES [dbo].[Ingredients] ([IngredientId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeIngredients] CHECK CONSTRAINT [FK_RecipeIngredients_Ingredients_IngredientId]
GO

ALTER TABLE [dbo].[RecipeIngredients]  WITH CHECK ADD  CONSTRAINT [FK_RecipeIngredients_Recipes_RecipeId] FOREIGN KEY([RecipeId])
REFERENCES [dbo].[Recipes] ([RecipeId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[RecipeIngredients] CHECK CONSTRAINT [FK_RecipeIngredients_Recipes_RecipeId]
GO


