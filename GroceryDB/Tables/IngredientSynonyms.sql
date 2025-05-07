USE [GroceryDB]
GO

/****** Object:  Table [dbo].[IngredientSynonyms]    Script Date: 5/6/2025 6:10:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IngredientSynonyms](
	[Name] [nvarchar](100) NULL,
	[Synonym] [nvarchar](100) NULL,
	[LLMReportOrder] [int] NOT NULL,
	[IsMisspelling] [bit] NOT NULL,
	[Region] [nvarchar](100) NULL,
	[LLMText] [nvarchar](100) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[IngredientSynonyms] ADD  DEFAULT ((0)) FOR [IsMisspelling]
GO


