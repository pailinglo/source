USE [GroceryDB]
GO

/****** Object:  Table [dbo].[IngredientName]    Script Date: 5/6/2025 10:38:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IngredientName](
	[IngredientId] [varchar](20) NOT NULL,
	[OriginalName] [varchar](100) NOT NULL,
	[LastNoun] [varchar](100) NOT NULL,
	[Processed] [varchar](100) NOT NULL,
 CONSTRAINT [PK_IngredientName] PRIMARY KEY CLUSTERED 
(
	[IngredientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[IngredientName]  WITH CHECK ADD  CONSTRAINT [FK_IngredientName_Ingredients_IngredientId] FOREIGN KEY([IngredientId])
REFERENCES [dbo].[Ingredients] ([IngredientId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[IngredientName] CHECK CONSTRAINT [FK_IngredientName_Ingredients_IngredientId]
GO


