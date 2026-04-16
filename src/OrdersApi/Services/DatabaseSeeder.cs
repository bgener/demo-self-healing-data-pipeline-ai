using MongoDB.Driver;
using OrdersApi.Models;

namespace OrdersApi.Services;

public class DatabaseSeeder
{
    private readonly IMongoDatabase _database;
    private readonly ILogger<DatabaseSeeder> _logger;

    public DatabaseSeeder(IMongoDatabase database, ILogger<DatabaseSeeder> logger)
    {
        _database = database;
        _logger = logger;
    }

    public async Task SeedAsync()
    {
        IMongoCollection<Customer> customers = _database.GetCollection<Customer>("customers");
        IMongoCollection<Order> orders = _database.GetCollection<Order>("orders");

        long customerCount = await customers.CountDocumentsAsync(FilterDefinition<Customer>.Empty);
        if (customerCount > 0)
        {
            _logger.LogInformation("Database already seeded with {Count} customers. Skipping.", customerCount);
            return;
        }

        _logger.LogInformation("Seeding database...");

        List<Customer> seedCustomers = GenerateCustomers();
        await customers.InsertManyAsync(seedCustomers);
        _logger.LogInformation("Inserted {Count} customers.", seedCustomers.Count);

        List<Order> seedOrders = GenerateOrders(seedCustomers);
        await orders.InsertManyAsync(seedOrders);
        _logger.LogInformation("Inserted {Count} orders.", seedOrders.Count);
    }

    private static List<Customer> GenerateCustomers()
    {
        string[] countries = ["NL", "DE", "US", "GB", "FR", "JP", "AU", "BR"];
        string[] segments = ["enterprise", "startup", "individual"];
        string[] firstNames = ["Alice", "Bob", "Carlos", "Diana", "Erik", "Fatima", "Guido", "Hana",
                               "Ivan", "Julia", "Kenji", "Lena", "Marco", "Nadia", "Oscar", "Priya"];
        string[] lastNames = ["Bakker", "Mueller", "Smith", "Johnson", "Dupont", "Tanaka", "Silva", "Weber"];

        Random rng = new(42);
        List<Customer> result = new();

        for (int i = 1; i <= 50; i++)
        {
            string first = firstNames[rng.Next(firstNames.Length)];
            string last = lastNames[rng.Next(lastNames.Length)];
            result.Add(new Customer
            {
                CustomerId = $"CUST-{i:D4}",
                Name = $"{first} {last}",
                Email = $"{first.ToLower()}.{last.ToLower()}@example.com",
                Country = countries[rng.Next(countries.Length)],
                Segment = segments[rng.Next(segments.Length)],
                CreatedAt = DateTime.UtcNow.AddDays(-rng.Next(30, 365))
            });
        }

        return result;
    }

    private static List<Order> GenerateOrders(List<Customer> customers)
    {
        string[] currencies = ["USD", "EUR", "GBP", "BTC", "ETH"];
        double[] currencyWeights = [0.35, 0.30, 0.15, 0.10, 0.10];
        string[] statuses = ["completed", "completed", "completed", "pending", "cancelled"];
        string[] shippingMethods = ["standard", "express", "overnight"];

        (string sku, string name, decimal price)[] products =
        [
            ("WIDGET-A", "Standard Widget", 29.99m),
            ("WIDGET-B", "Premium Widget", 59.99m),
            ("GADGET-X", "Smart Gadget", 149.00m),
            ("GADGET-Y", "Pro Gadget", 299.00m),
            ("CABLE-USB", "USB-C Cable", 12.99m),
            ("ADAPTER-PWR", "Power Adapter", 24.99m),
            ("CASE-PROT", "Protective Case", 34.99m),
            ("SCREEN-GRD", "Screen Guard", 9.99m),
        ];

        Random rng = new(42);
        List<Order> result = new();

        for (int i = 1; i <= 500; i++)
        {
            Customer customer = customers[rng.Next(customers.Count)];
            int itemCount = rng.Next(1, 5);
            List<OrderItem> items = new();

            for (int j = 0; j < itemCount; j++)
            {
                var product = products[rng.Next(products.Length)];
                items.Add(new OrderItem
                {
                    Sku = product.sku,
                    ProductName = product.name,
                    Qty = rng.Next(1, 6),
                    UnitPrice = product.price
                });
            }

            string currency = PickWeighted(currencies, currencyWeights, rng);

            result.Add(new Order
            {
                OrderId = $"ORD-{i:D5}",
                CustomerId = customer.CustomerId,
                Status = statuses[rng.Next(statuses.Length)],
                Currency = currency,
                Items = items,
                Shipping = new ShippingInfo
                {
                    Country = customer.Country,
                    Method = shippingMethods[rng.Next(shippingMethods.Length)]
                },
                CreatedAt = DateTime.UtcNow.AddDays(-rng.Next(0, 90)).AddHours(-rng.Next(0, 24))
            });
        }

        return result;
    }

    private static string PickWeighted(string[] values, double[] weights, Random rng)
    {
        double total = weights.Sum();
        double roll = rng.NextDouble() * total;
        double cumulative = 0;

        for (int i = 0; i < values.Length; i++)
        {
            cumulative += weights[i];
            if (roll <= cumulative)
                return values[i];
        }

        return values[^1];
    }
}
