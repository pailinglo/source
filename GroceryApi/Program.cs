using Microsoft.EntityFrameworkCore;
using GroceryApi.Data;
using GroceryApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // Handle circular references in JSON serialization
        // options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.Preserve;
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddDbContext<GroceryContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IngredientService>();
builder.Services.AddScoped<RecipeService>();


// Add JWT authentication (optional, enable for production)
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer(options =>
    {
        options.Authority = "https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_signupsignin";
        options.Audience = "your-api-id";
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure CORS policy to allow requests from specific origins
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevPolicy", policy => policy
        .AllowAnyOrigin()
        .AllowAnyHeader()
        .AllowAnyMethod());

    options.AddPolicy("ProdPolicy", policy => policy
        .WithOrigins("https://your-production-app.com")
        .AllowAnyHeader()
        .AllowAnyMethod());
});


// builder.WebHost.UseUrls("http://0.0.0.0:5000", "https://0.0.0.0:5001");

var app = builder.Build();

// Apply policy based on environment
if (app.Environment.IsDevelopment())
{
    app.UseCors("DevPolicy");
}
else
{
    app.UseCors("ProdPolicy");
}


// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Serve static files from the specified directory. TO-DO: Change to your image hosting to blob storage
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(@"C:\Users\paili\recipe_images"),
    RequestPath = "/images"
});

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();