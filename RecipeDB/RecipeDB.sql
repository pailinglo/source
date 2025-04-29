-- Table for raw API responses
CREATE TABLE RawRecipeData (
    recipeId INT PRIMARY KEY,
    rawResponse NVARCHAR(MAX),
    fetchDateTime DATETIME2
);

-- Table for parsed recipe information
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
    fetchDateTime DATETIME2
);

-- Table for ingredients
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

ALTER TABLE Recipes ADD imageDownloaded BIT DEFAULT 0;
ALTER TABLE Recipes ADD imageFileType VARCHAR(10) NULL;

-- Add more fields --
-- Main Recipes table (updated)
ALTER TABLE Recipes ADD glutenFree BIT;
ALTER TABLE Recipes ADD veryPopular BIT;
ALTER TABLE Recipes ADD aggregateLikes INT;
ALTER TABLE Recipes ADD instructions NVARCHAR(MAX);

-- Cuisines table (many-to-many relationship)
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

-- DishTypes table (many-to-many relationship)
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

-- Add the sourceName column to Recipes table
ALTER TABLE Recipes ADD sourceName NVARCHAR(100) NULL;

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