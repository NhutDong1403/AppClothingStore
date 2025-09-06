using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using ClothingStoreAPI.Data;

namespace ClothingStoreAPI.Services
{
    public class CartService
    {
        private readonly List<CartItem> _cart = new();
        private readonly ApplicationDbContext _context;

        public CartService(ApplicationDbContext context)
        {
            _context = context;
        }

        public List<CartItemDto> GetCart()
        {
            return _cart.Select(item => new CartItemDto
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                Product = _context.Products.FirstOrDefault(p => p.Id == item.ProductId)!
            }).ToList();
        }

        public void AddItem(CartItem item)
        {
            var existing = _cart.FirstOrDefault(x => x.ProductId == item.ProductId);
            if (existing != null)
            {
                existing.Quantity += item.Quantity;
            }
            else
            {
                _cart.Add(item);
            }
        }

        public void UpdateItem(int productId, int quantity)
        {
            var item = _cart.FirstOrDefault(x => x.ProductId == productId);
            if (item != null)
            {
                item.Quantity = quantity;
            }
        }

        public void RemoveItem(int productId)
        {
            var item = _cart.FirstOrDefault(x => x.ProductId == productId);
            if (item != null)
            {
                _cart.Remove(item);
            }
        }

        public void ClearCart()
        {
            _cart.Clear();
        }
    }
}
