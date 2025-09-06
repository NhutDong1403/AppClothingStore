namespace ClothingStoreAPI.Models
{
    public class Order
    {
        public int Id { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime OrderDate { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public string? ReceiverName { get; set; } = string.Empty;
        public string? Phone { get; set; } = string.Empty;
        public string? Address { get; set; } = string.Empty;
        public string? Note { get; set; } = string.Empty;

        public string Status { get; set; } = "Đang xử lý";

        public string? VoucherCode { get; set; }
        public string PaymentMethod { get; set; } = "COD";

        public decimal OriginalAmount { get; set; } = 0; // ✅ Tổng tiền gốc (chưa giảm)
        public decimal Discount { get; set; } = 0;        // ✅ Phần trăm giảm giá
        public decimal TotalAmount { get; set; }          // ✅ Tổng tiền sau khi giảm




        public ICollection<OrderDetail> OrderDetails { get; set; } = new List<OrderDetail>();
    }
}
