namespace ClothingStoreAPI.DTOs
{
    public class CategoryDTO
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;

        public List<ProductDTO>? Products { get; set; }
    }
}
