namespace ClothingStoreAPI.DTOs
{
    public class OrderItemDTO
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }

        // Không required ở phía client
        public string? ProductName { get; set; }
    }
}
