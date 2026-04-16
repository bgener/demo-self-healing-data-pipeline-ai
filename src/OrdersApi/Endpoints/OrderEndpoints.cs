using MongoDB.Driver;
using OrdersApi.Models;
using OrdersApi.Services;

namespace OrdersApi.Endpoints;

public static class OrderEndpoints
{
    public static void MapOrderEndpoints(this WebApplication app)
    {
        RouteGroupBuilder group = app.MapGroup("/api/orders").WithTags("Orders");

        // GET /api/orders - list orders with optional status filter
        group.MapGet("/", async (IMongoDatabase db, string? status, int limit = 20) =>
        {
            IMongoCollection<Order> collection = db.GetCollection<Order>("orders");
            FilterDefinition<Order> filter = status is not null
                ? Builders<Order>.Filter.Eq(o => o.Status, status)
                : FilterDefinition<Order>.Empty;

            List<Order> orders = await collection.Find(filter)
                .SortByDescending(o => o.CreatedAt)
                .Limit(limit)
                .ToListAsync();

            return Results.Ok(orders);
        });

        // GET /api/orders/{orderId}
        group.MapGet("/{orderId}", async (IMongoDatabase db, string orderId) =>
        {
            IMongoCollection<Order> collection = db.GetCollection<Order>("orders");
            Order? order = await collection.Find(o => o.OrderId == orderId).FirstOrDefaultAsync();
            return order is not null ? Results.Ok(order) : Results.NotFound();
        });

        // GET /api/orders/revenue/daily - MongoDB aggregation pipeline
        group.MapGet("/revenue/daily", async (RevenueAggregationService service, int days = 30) =>
        {
            List<DailyRevenue> revenue = await service.GetDailyRevenueAsync(days);
            return Results.Ok(revenue);
        });
    }
}
