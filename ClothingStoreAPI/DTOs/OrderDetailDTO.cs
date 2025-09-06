namespace ClothingStoreAPI.DTOs
{
    public class OrderDetailDTO
    {
        public int Id { get; set; } // ← Thêm dòng này nếu bạn cần dùng .Id
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public string? ProductName { get; set; }
    }
}
