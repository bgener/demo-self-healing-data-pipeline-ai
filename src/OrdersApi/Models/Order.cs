using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace OrdersApi.Models;

public class Order
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("orderId")]
    public string OrderId { get; set; } = null!;

    [BsonElement("customerId")]
    public string CustomerId { get; set; } = null!;

    [BsonElement("status")]
    public string Status { get; set; } = null!;

    [BsonElement("currency")]
    public string Currency { get; set; } = null!;

    [BsonElement("items")]
    public List<OrderItem> Items { get; set; } = new();

    [BsonElement("shipping")]
    public ShippingInfo Shipping { get; set; } = null!;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; }
}

public class OrderItem
{
    [BsonElement("sku")]
    public string Sku { get; set; } = null!;

    [BsonElement("productName")]
    public string ProductName { get; set; } = null!;

    [BsonElement("qty")]
    public int Qty { get; set; }

    [BsonElement("unitPrice")]
    public decimal UnitPrice { get; set; }
}

public class ShippingInfo
{
    [BsonElement("country")]
    public string Country { get; set; } = null!;

    [BsonElement("method")]
    public string Method { get; set; } = null!;
}
