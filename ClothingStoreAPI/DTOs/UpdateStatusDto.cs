using System.ComponentModel.DataAnnotations;

namespace ClothingStoreAPI.DTOs
{
    public class UpdateStatusDto
    {
        [Required]
        public string Status { get; set; }
    }
}
