using System.ComponentModel.DataAnnotations;

namespace ClothingStoreAPI.DTOs
{
    public class CreateCategoryDTO
    {
        [Required (ErrorMessage = "Tên danh mục không được để trống")]
        public string Name { get; set; } = null!;
    }
}
