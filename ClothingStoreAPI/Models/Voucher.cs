using System.ComponentModel.DataAnnotations;

namespace ClothingStoreAPI.Models
{
    public class Voucher
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public int DiscountPercent { get; set; }
        public DateTime ExpiryDate { get; set; }
    }
}
