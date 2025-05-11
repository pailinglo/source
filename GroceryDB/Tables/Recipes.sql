USE [GroceryDB]
GO

/****** Object:  Table [dbo].[Recipes]    Script Date: 5/10/2025 10:11:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Recipes](
	[RecipeId] [varchar](20) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Instructions] [nvarchar](max) NOT NULL,
	[IngredientCount] [int] NOT NULL,
	[MajorIngredientCount] [int] NOT NULL,
	[ImageUrl] [varchar](255) NOT NULL,
	[ReadyInMinutes] [int] NOT NULL,
	[Servings] [int] NOT NULL,
	[SourceUrl] [varchar](500) NOT NULL,
	[Vegetarian] [bit] NOT NULL,
	[Vegan] [bit] NOT NULL,
	[PreparationMinutes] [int] NOT NULL,
	[CookingMinutes] [int] NOT NULL,
	[GlutenFree] [bit] NOT NULL,
	[VeryPopular] [bit] NOT NULL,
	[AggregateLikes] [int] NOT NULL,
	[SourceName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_Recipes] PRIMARY KEY CLUSTERED 
(
	[RecipeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT (N'') FOR [Instructions]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [IngredientCount]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [MajorIngredientCount]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ('') FOR [ImageUrl]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [ReadyInMinutes]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((1)) FOR [Servings]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ('') FOR [SourceUrl]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT (CONVERT([bit],(0))) FOR [Vegetarian]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT (CONVERT([bit],(0))) FOR [Vegan]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [PreparationMinutes]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [CookingMinutes]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT (CONVERT([bit],(0))) FOR [GlutenFree]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT (CONVERT([bit],(0))) FOR [VeryPopular]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ((0)) FOR [AggregateLikes]
GO

ALTER TABLE [dbo].[Recipes] ADD  DEFAULT ('') FOR [SourceName]
GO


