using ClothingStoreAPI.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class RevenueController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public RevenueController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 1. Tổng doanh thu theo khoảng thời gian
        [HttpGet]
        public async Task<IActionResult> GetTotalRevenue([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var orders = _context.Orders
                .Where(o => o.Status == "Hoàn thành");

            if (startDate.HasValue)
                orders = orders.Where(o => o.OrderDate >= startDate.Value);

            if (endDate.HasValue)
                orders = orders.Where(o => o.OrderDate <= endDate.Value);

            var totalRevenue = await orders.SumAsync(o => o.TotalAmount);

            return Ok(new
            {
                revenue = totalRevenue,
                from = startDate,
                to = endDate
            });
        }

        // 2. Doanh thu theo từng ngày trong khoảng (để làm biểu đồ line/bar)
        [HttpGet("daily")]
        public async Task<IActionResult> GetDailyRevenue([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            var orders = _context.Orders
                .Where(o => o.Status == "Hoàn thành");

            if (startDate.HasValue)
                orders = orders.Where(o => o.OrderDate.Date >= startDate.Value.Date);
            if (endDate.HasValue)
                orders = orders.Where(o => o.OrderDate.Date <= endDate.Value.Date);

            var revenueByDay = await orders
                .GroupBy(o => o.OrderDate.Date)
                .Select(g => new
                {
                    Date = g.Key,
                    Revenue = g.Sum(x => x.TotalAmount)
                })
                .OrderBy(r => r.Date)
                .ToListAsync();

            return Ok(revenueByDay);
        }

        // (Tuỳ chọn) 3. Doanh thu theo tháng trong năm
        [HttpGet("monthly")]
        public async Task<IActionResult> GetMonthlyRevenue([FromQuery] int? year)
        {
            var orders = _context.Orders
                .Where(o => o.Status == "Hoàn thành");

            if (year.HasValue)
                orders = orders.Where(o => o.OrderDate.Year == year.Value);

            var revenueByMonth = await orders
                .GroupBy(o => new { o.OrderDate.Year, o.OrderDate.Month })
                .Select(g => new
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    Revenue = g.Sum(x => x.TotalAmount)
                })
                .OrderBy(r => r.Year)
.ThenBy(r => r.Month)
                .ToListAsync();

            return Ok(revenueByMonth);
        }
    }
}