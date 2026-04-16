namespace OrdersApi.Models;

public class DailyRevenue
{
    public string Date { get; set; } = null!;
    public string Currency { get; set; } = null!;
    public decimal TotalRevenue { get; set; }
    public int OrderCount { get; set; }
    public int ItemsSold { get; set; }
}
