using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace OrdersApi.Models;

public class Customer
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("customerId")]
    public string CustomerId { get; set; } = null!;

    [BsonElement("name")]
    public string Name { get; set; } = null!;

    [BsonElement("email")]
    public string Email { get; set; } = null!;

    [BsonElement("country")]
    public string Country { get; set; } = null!;

    [BsonElement("segment")]
    public string Segment { get; set; } = null!;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; }
}
