using MongoDB.Bson;
using MongoDB.Driver;
using OrdersApi.Models;

namespace OrdersApi.Services;

/// <summary>
/// Demonstrates real MongoDB aggregation pipelines on the operational source database.
/// This is the kind of query the source database handles natively:
/// $unwind nested items, $group by date and currency, $sort by date.
/// The ELT pipeline complements this by enriching with external data
/// (CoinGecko prices) and building cross-source analytical models.
/// </summary>
public class RevenueAggregationService
{
    private readonly IMongoDatabase _database;

    public RevenueAggregationService(IMongoDatabase database)
    {
        _database = database;
    }

    /// <summary>
    /// Aggregation pipeline: daily revenue grouped by currency.
    /// Uses $unwind to flatten nested items array, then $group by date + currency.
    /// </summary>
    public async Task<List<DailyRevenue>> GetDailyRevenueAsync(int days = 30)
    {
        IMongoCollection<Order> orders = _database.GetCollection<Order>("orders");

        DateTime cutoff = DateTime.UtcNow.AddDays(-days);

        // MongoDB aggregation pipeline running on the source database
        PipelineDefinition<Order, BsonDocument> pipeline = new BsonDocument[]
        {
            // Stage 1: Filter to completed orders within the date range
            new BsonDocument("$match", new BsonDocument
            {
                { "status", "completed" },
                { "createdAt", new BsonDocument("$gte", cutoff) }
            }),

            // Stage 2: Unwind the nested items array (one doc per line item)
            new BsonDocument("$unwind", "$items"),

            // Stage 3: Group by date + currency, sum revenue and count
            new BsonDocument("$group", new BsonDocument
            {
                { "_id", new BsonDocument
                    {
                        { "date", new BsonDocument("$dateToString", new BsonDocument
                            {
                                { "format", "%Y-%m-%d" },
                                { "date", "$createdAt" }
                            })
                        },
                        { "currency", "$currency" }
                    }
                },
                { "totalRevenue", new BsonDocument("$sum",
                    new BsonDocument("$multiply", new BsonArray { "$items.qty", "$items.unitPrice" }))
                },
                { "orderCount", new BsonDocument("$sum", 1) },
                { "itemsSold", new BsonDocument("$sum", "$items.qty") }
            }),

            // Stage 4: Sort by date descending
            new BsonDocument("$sort", new BsonDocument("_id.date", -1))
        };

        List<BsonDocument> results = await orders.Aggregate(pipeline).ToListAsync();

        return results.Select(doc => new DailyRevenue
        {
            Date = doc["_id"]["date"].AsString,
            Currency = doc["_id"]["currency"].AsString,
            TotalRevenue = doc["totalRevenue"].ToDecimal(),
            OrderCount = doc["orderCount"].AsInt32,
            ItemsSold = doc["itemsSold"].AsInt32
        }).ToList();
    }
}
