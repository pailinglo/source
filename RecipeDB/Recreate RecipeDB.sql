-- Disable foreign key constraints temporarily
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'

-- Drop all tables (order matters due to foreign key relationships)
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecipeIngredients')
    DROP TABLE RecipeIngredients;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecipeCuisines')
    DROP TABLE RecipeCuisines;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RecipeDishTypes')
    DROP TABLE RecipeDishTypes;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cuisines')
    DROP TABLE Cuisines;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DishTypes')
    DROP TABLE DishTypes;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Recipes')
    DROP TABLE Recipes;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'RawRecipeData')
    DROP TABLE RawRecipeData;

-- Re-enable foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL'

-- Recreate all tables with current schema
CREATE TABLE RawRecipeData (
    recipeId INT PRIMARY KEY,
    rawResponse NVARCHAR(MAX),
    fetchDateTime DATETIME2
);

CREATE TABLE Recipes (
    id INT PRIMARY KEY,
    image NVARCHAR(255),
    title NVARCHAR(255),
    readyInMinutes INT,
    servings INT,
    sourceUrl NVARCHAR(255),
    vegetarian BIT,
    vegan BIT,
    preparationMinutes INT,
    cookingMinutes INT,
    glutenFree BIT,
    veryPopular BIT,
    aggregateLikes INT,
    instructions NVARCHAR(MAX),
    imageDownloaded BIT DEFAULT 0,
    imageFileType VARCHAR(10) NULL,
    fetchDateTime DATETIME2,
    sourceName NVARCHAR(100) NULL,
	imageQuality INT NULL
);

CREATE TABLE RecipeIngredients (
    id INT IDENTITY(1,1) PRIMARY KEY,
    recipeId INT,
    ingredientId INT,
    name NVARCHAR(255),
    nameClean NVARCHAR(255),
    original NVARCHAR(MAX),
    originalName NVARCHAR(255),
    amount DECIMAL(10,2),
    unit NVARCHAR(100),
    FOREIGN KEY (recipeId) REFERENCES Recipes(id)
);

CREATE TABLE Cuisines (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE
);

CREATE TABLE RecipeCuisines (
    recipeId INT,
    cuisineId INT,
    PRIMARY KEY (recipeId, cuisineId),
    FOREIGN KEY (recipeId) REFERENCES Recipes(id),
    FOREIGN KEY (cuisineId) REFERENCES Cuisines(id)
);

CREATE TABLE DishTypes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE
);

CREATE TABLE RecipeDishTypes (
    recipeId INT,
    dishTypeId INT,
    PRIMARY KEY (recipeId, dishTypeId),
    FOREIGN KEY (recipeId) REFERENCES Recipes(id),
    FOREIGN KEY (dishTypeId) REFERENCES DishTypes(id)
);

CREATE TABLE RecipeUrlStatus (
    RecipeId int NOT NULL PRIMARY KEY,
    SourceUrl VARCHAR(500) NOT NULL,
    IsAccessible BIT NULL,
    LastChecked DATETIME2 NULL,
    HttpStatus INT NULL,
    ErrorMessage NVARCHAR(500) NULL,
    RetryCount INT NOT NULL DEFAULT 0,
    NextCheckDate DATETIME2 NULL,
    CONSTRAINT FK_RecipeUrlStatus_Recipes FOREIGN KEY (RecipeId) 
        REFERENCES Recipes(id) ON DELETE CASCADE
);

-- Create index for performance
CREATE INDEX IX_RecipeUrlStatus_NextCheckDate ON RecipeUrlStatus(NextCheckDate)
WHERE NextCheckDate IS NOT NULL;

PRINT 'Database has been completely reset and all tables recreated';