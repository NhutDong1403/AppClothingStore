using System.ComponentModel.DataAnnotations;

namespace ClothingStoreAPI.DTOs
{
    public class ProductDTO
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Tên sản phẩm không được bỏ trống")]
        [StringLength(100)]
        public string Name { get; set; } = null!;

        [Required(ErrorMessage = "Mô tả không được bỏ trống")]
        [StringLength(1000)]
        public string Description { get; set; } = null!;

        [Range(0.01, double.MaxValue, ErrorMessage = "Giá sản phẩm phải lớn hơn 0")]
        public decimal Price { get; set; }


        [Required(ErrorMessage = "Kích cỡ không được để trống")]
        [StringLength(10)]
        public string Size { get; set; } = null!;

        [Required(ErrorMessage = "Màu sắc không được để trống")]
        [StringLength(20)]
        public string Color { get; set; } = null!;

        [Range(0, int.MaxValue, ErrorMessage = "Tồn kho phải là số không âm")]
        public int Stock { get; set; }

        [Required(ErrorMessage = "Ảnh sản phẩm không được để trống")]
        public string? ImageUrl { get; set; } 

        [Range(1, int.MaxValue, ErrorMessage = "Danh mục không hợp lệ")]
        
        public int CategoryId { get; set; }

        public int SoldCount { get; set; }   

        public double AvgRating { get; set; }
    }

}
