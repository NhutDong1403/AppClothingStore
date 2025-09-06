namespace ClothingStoreAPI.DTOs
{
    public class VoucherDto
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public int DiscountPercent { get; set; }
        public DateTime ExpiryDate { get; set; }
    }
}
