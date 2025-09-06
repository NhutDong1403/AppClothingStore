namespace ClothingStoreAPI.DTOs
{
    public class CreateOrderDTO
    {
        public string ReceiverName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string? Note { get; set; }
        public string? Status { get; set; } = "Đang xử lý";
        public string? VoucherCode { get; set; }
        public string PaymentMethod { get; set; } = "COD";

        public decimal OriginalAmount { get; set; }       // ✅ Thêm dòng này
        public decimal TotalAmount { get; set; }
        public string? UserId { get; set; }     // ✅ THÊM nếu cần
        public decimal Discount { get; set; } = 0; // ✅ THÊM nếu cần

        public List<CreateOrderItemDTO> Items { get; set; } = new();

    }
}
