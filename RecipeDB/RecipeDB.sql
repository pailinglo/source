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
