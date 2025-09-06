using ClothingStoreAPI.Data;
using ClothingStoreAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


namespace ClothingStoreAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RatingController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public RatingController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/Rating
        [HttpPost]
        public async Task<IActionResult> CreateRating([FromBody] Rating rating)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (rating.RatingValue < 1 || rating.RatingValue > 5)
                return BadRequest(new { message = "RatingValue must be between 1 and 5." });

            // Gán CreatedAt nếu chưa có
            if (rating.CreatedAt == default)
                rating.CreatedAt = DateTime.UtcNow;

            _context.Ratings.Add(rating);
            await _context.SaveChangesAsync();

            // Tính lại trung bình rating
            var avgRating = await _context.Ratings
                .Where(r => r.ProductId == rating.ProductId)
                .AverageAsync(r => r.RatingValue);

            // Cập nhật cột AvgRating của bảng Product
            var product = await _context.Products.FindAsync(rating.ProductId);
            if (product != null)
            {
                product.AvgRating = avgRating;
                await _context.SaveChangesAsync();
            }

            return Ok(new
            {
                message = "Đánh giá thành công",
                avgRating = avgRating
            });
        }

        // GET: api/Rating/product/5
        [HttpGet("product/{productId}")]
        public async Task<IActionResult> GetRatingsByProduct(int productId)
        {
            var ratings = await _context.Ratings
                .Where(r => r.ProductId == productId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(ratings);
        }
    }
}
