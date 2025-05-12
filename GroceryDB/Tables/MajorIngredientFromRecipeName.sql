USE [GroceryDB]
GO

/****** Object:  Table [dbo].[MajorIngredientFromRecipeName]    Script Date: 5/9/2025 1:20:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MajorIngredientFromRecipeName](
	[RecipeId] [varchar](20) NOT NULL,
	[IngredientId] [varchar](20) NOT NULL,
	[LLM] [varchar](20) NULL
) ON [PRIMARY]
GO


