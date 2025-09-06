using ClothingStoreAPI.Models;

namespace ClothingStoreAPI.DTOs
{
    public class CartItemDto
    {
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int Quantity { get; set; }
        public Product Product { get; set; } = null!;
    }
}
