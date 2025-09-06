using ClothingStoreAPI.Models;

public class Category
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public ICollection<Product> Products { get; set; }

    public Category()
    {
        Products = new List<Product>();
    }
}
