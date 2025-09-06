using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using ClothingStoreAPI.Data;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public ProductController(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        // GET: api/Product (Chỉ Admin)
        [HttpGet("public")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<ProductDTO>>> GetProducts()
        {
            var products = await _context.Products.Include(p => p.Category).ToListAsync();
            var productsDto = _mapper.Map<List<ProductDTO>>(products);
            return Ok(productsDto);
        }

        // GET: api/Product/5
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<ProductDTO>> GetProduct(int id)
        {
            var product = await _context.Products.Include(p => p.Category)
                                                 .FirstOrDefaultAsync(p => p.Id == id);
            if (product == null) return NotFound();

            var productDto = _mapper.Map<ProductDTO>(product);
            return Ok(productDto);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] ProductDTO dto)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
            {
                return NotFound(new { message = "Sản phẩm không tồn tại." });
            }

            // Cập nhật thông tin
            product.Name = dto.Name;
            product.Description = dto.Description;
            product.Price = dto.Price;
            product.Size = dto.Size;
            product.Color = dto.Color;
            product.Stock = dto.Stock;
            product.ImageUrl = dto.ImageUrl;
            product.CategoryId = dto.CategoryId;

            await _context.SaveChangesAsync();

            return Ok(new { message = "✅ Đã cập nhật sản phẩm thành công." });
        }


        // POST: api/Product/Create (Chỉ Admin)
        [HttpPost("Create")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Create([FromBody] ProductDTO dto)
        {
            if (!ModelState.IsValid)
            {
                foreach (var error in ModelState)
                {
                    Console.WriteLine($"❌ {error.Key}: {string.Join(", ", error.Value.Errors.Select(e => e.ErrorMessage))}");
                }
                return BadRequest(ModelState);
            }

            // ✅ Kiểm tra bổ sung ImageUrl
            if (string.IsNullOrWhiteSpace(dto.ImageUrl))
            {
                ModelState.AddModelError("ImageUrl", "Ảnh sản phẩm không được để trống");
                return BadRequest(ModelState);
            }

            var product = new Product
            {
                Name = dto.Name,
                Description = dto.Description,
                Price = dto.Price,
                ImageUrl = dto.ImageUrl,
                Stock = dto.Stock,
                CategoryId = dto.CategoryId,
                Color = dto.Color,
                Size = dto.Size
            };

            _context.Products.Add(product);

            try
            {
                await _context.SaveChangesAsync();
                return StatusCode(201, product);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Lỗi khi lưu sản phẩm: {ex.Message}");
                return StatusCode(500, "Lỗi khi lưu sản phẩm vào cơ sở dữ liệu");
            }
        }

        // POST: api/Product/upload
        [HttpPost("upload")]
        public async Task<IActionResult> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("File ảnh không hợp lệ");

            var fileName = Guid.NewGuid().ToString() + Path.GetExtension(file.FileName);
            var filePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot/images", fileName);

            Directory.CreateDirectory(Path.GetDirectoryName(filePath)!); // tạo folder nếu chưa có

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var imageUrl = $"http://localhost:7010/images/{fileName}";
            return Ok(new
            {
                fileName,
                imageUrl
            });
        }

        // DELETE: api/Product/5 (Chỉ Admin)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        [HttpPost("submit-rating")]
        public async Task<IActionResult> SubmitRating([FromBody] UpdateProductRatingDTO dto)
        {
            if (dto.Rating < 1 || dto.Rating > 5)
                return BadRequest("Rating phải từ 1 đến 5.");

            var product = await _context.Products.FindAsync(dto.ProductId);
            if (product == null)
                return NotFound("Sản phẩm không tồn tại.");

            var userIdClaim = User.FindFirst("sub")?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
                return BadRequest("Không xác định được User.");

            int userId = int.Parse(userIdClaim);

            // Kiểm tra đã đánh giá chưa
            var existingRating = await _context.Ratings
                .FirstOrDefaultAsync(r => r.ProductId == dto.ProductId && r.UserId == userId);

            if (existingRating != null)
            {
                existingRating.RatingValue = (int)Math.Round(dto.Rating);
                existingRating.CreatedAt = DateTime.UtcNow;
            }
            else
            {
                var newRating = new Rating
                {
                    ProductId = dto.ProductId,
                    UserId = userId,
                    RatingValue = (int)Math.Round(dto.Rating),
                    CreatedAt = DateTime.UtcNow
                };
                _context.Ratings.Add(newRating);
            }

            await _context.SaveChangesAsync();

            // Tính trung bình mới
            var avg = await _context.Ratings
                .Where(r => r.ProductId == dto.ProductId)
                .AverageAsync(r => r.RatingValue);

            product.AvgRating = avg;
            await _context.SaveChangesAsync();

            return Ok(new { message = "✅ Đánh giá đã được lưu.", avgRating = avg });
        }





        [HttpGet("{productId}/rating-by-user")]
        public async Task<IActionResult> GetUserRating(int productId)
        {
            var userIdClaim = User.FindFirst("sub")?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
                return BadRequest("Không xác định được User.");

            int userId = int.Parse(userIdClaim);

            var rating = await _context.Ratings
                .Where(r => r.ProductId == productId && r.UserId == userId)
                .Select(r => (int?)r.RatingValue) // nullable để phân biệt không có
                .FirstOrDefaultAsync();

            return Ok(new
            {
                userId,
                rating // sẽ trả về null nếu chưa có
            });
        }

        [HttpGet("search")]
        public async Task<IActionResult> SearchProducts(string query)
        {
            if (string.IsNullOrWhiteSpace(query))
                return BadRequest("Từ khóa không được để trống");

            var results = await _context.Products
                .Where(p => p.Name.Contains(query))
                .ToListAsync();

            return Ok(results);
        }



        private bool ProductExists(int id)
        {
            return _context.Products.Any(e => e.Id == id);
        }
    }
}
