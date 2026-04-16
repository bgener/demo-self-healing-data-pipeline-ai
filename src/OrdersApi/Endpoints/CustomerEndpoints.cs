using MongoDB.Driver;
using OrdersApi.Models;

namespace OrdersApi.Endpoints;

public static class CustomerEndpoints
{
    public static void MapCustomerEndpoints(this WebApplication app)
    {
        RouteGroupBuilder group = app.MapGroup("/api/customers").WithTags("Customers");

        // GET /api/customers
        group.MapGet("/", async (IMongoDatabase db, string? country, int limit = 20) =>
        {
            IMongoCollection<Customer> collection = db.GetCollection<Customer>("customers");
            FilterDefinition<Customer> filter = country is not null
                ? Builders<Customer>.Filter.Eq(c => c.Country, country)
                : FilterDefinition<Customer>.Empty;

            List<Customer> customers = await collection.Find(filter)
                .SortBy(c => c.CustomerId)
                .Limit(limit)
                .ToListAsync();

            return Results.Ok(customers);
        });

        // GET /api/customers/{customerId}
        group.MapGet("/{customerId}", async (IMongoDatabase db, string customerId) =>
        {
            IMongoCollection<Customer> collection = db.GetCollection<Customer>("customers");
            Customer? customer = await collection.Find(c => c.CustomerId == customerId).FirstOrDefaultAsync();
            return customer is not null ? Results.Ok(customer) : Results.NotFound();
        });
    }
}
