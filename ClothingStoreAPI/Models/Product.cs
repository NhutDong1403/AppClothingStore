using System.ComponentModel.DataAnnotations.Schema;

namespace ClothingStoreAPI.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string Name { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Price { get; set; }
        public string Size { get; set; } = null!;
        public string Color { get; set; } = null!;
        public int Stock { get; set; }
        public string ImageUrl { get; set; } = null!;

        public int CategoryId { get; set; }
        public int SoldCount { get; set; }
        public double AvgRating { get; set; }


        [ForeignKey("CategoryId")]
        public Category? Category { get; set; }

        public virtual ICollection<Rating> Ratings { get; set; }

    }
}
