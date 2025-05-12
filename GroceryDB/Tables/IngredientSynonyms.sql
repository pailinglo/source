USE [GroceryDB]
GO

/****** Object:  Table [dbo].[IngredientSynonyms]    Script Date: 5/7/2025 11:28:51 PM ******/
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

CREATE NONCLUSTERED INDEX [IX_IngredientSynonyms_Name] ON [dbo].[IngredientSynonyms] ([Name])
GO

CREATE NONCLUSTERED INDEX [IX_IngredientSynonyms_Synonym] ON [dbo].[IngredientSynonyms] ([Synonym])
GO