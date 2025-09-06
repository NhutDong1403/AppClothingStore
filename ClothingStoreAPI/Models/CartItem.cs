using System.ComponentModel.DataAnnotations;

namespace ClothingStoreAPI.Models
{
    public class CartItem
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public int ProductId { get; set; }

        public int Quantity { get; set; }

        // Navigation
        public User? User { get; set; }
        public Product? Product { get; set; }
    }
}
