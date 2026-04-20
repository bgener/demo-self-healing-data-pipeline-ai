using MongoDB.Driver;
using OrdersApi.Endpoints;
using OrdersApi.Services;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

// MongoDB connection
string connectionString = builder.Configuration["DocumentDb:ConnectionString"]
    ?? "mongodb://localhost:27017";
string databaseName = builder.Configuration["DocumentDb:DatabaseName"] ?? "ecommerce";

MongoClient mongoClient = new(connectionString);
IMongoDatabase database = mongoClient.GetDatabase(databaseName);

builder.Services.AddSingleton(database);
builder.Services.AddSingleton<DatabaseSeeder>();
builder.Services.AddSingleton<RevenueAggregationService>();
builder.Services.AddOpenApi();

WebApplication app = builder.Build();

// Seed the database on startup
using (IServiceScope scope = app.Services.CreateScope())
{
    DatabaseSeeder seeder = scope.ServiceProvider.GetRequiredService<DatabaseSeeder>();
    await seeder.SeedAsync();
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapOrderEndpoints();
app.MapCustomerEndpoints();

app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.Run();
