USE [GroceryDB]
GO

/****** Object:  Table [dbo].[UserIngredients]    Script Date: 5/6/2025 10:41:07 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UserIngredients](
	[UserId] [varchar](254) NOT NULL,
	[IngredientId] [varchar](20) NOT NULL,
 CONSTRAINT [PK_UserIngredients] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC,
	[IngredientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[UserIngredients]  WITH CHECK ADD  CONSTRAINT [FK_UserIngredients_Ingredients_IngredientId] FOREIGN KEY([IngredientId])
REFERENCES [dbo].[Ingredients] ([IngredientId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[UserIngredients] CHECK CONSTRAINT [FK_UserIngredients_Ingredients_IngredientId]
GO

ALTER TABLE [dbo].[UserIngredients]  WITH CHECK ADD  CONSTRAINT [FK_UserIngredients_Users_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[UserIngredients] CHECK CONSTRAINT [FK_UserIngredients_Users_UserId]
GO


