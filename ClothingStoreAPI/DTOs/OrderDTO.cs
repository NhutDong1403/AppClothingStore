namespace ClothingStoreAPI.DTOs
{
    public class OrderDTO
    {
        public int Id { get; set; }

        public DateTime CreatedAt { get; set; }

        public decimal TotalAmount { get; set; }

        public decimal Discount { get; set; } = 0; // ✅ Giảm giá nếu có

        public string? ReceiverName { get; set; }

        public string? Phone { get; set; }

        public string? Address { get; set; }

        public string? Note { get; set; }
        public decimal OriginalAmount { get; set; }


        public string Status { get; set; } = "Đang xử lý";

        public string? VoucherCode { get; set; }

        public string PaymentMethod { get; set; } = "COD";

        public List<OrderItemDTO> Items { get; set; } = new();
    }
}
