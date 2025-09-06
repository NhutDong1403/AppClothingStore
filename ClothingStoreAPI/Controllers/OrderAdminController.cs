using AutoMapper;
using ClothingStoreAPI.Data;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using ClothingStoreAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/admin/orders")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class OrderAdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly IEmailService _emailService;

        public OrderAdminController(ApplicationDbContext context, IMapper mapper, IEmailService emailService)
        {
            _context = context;
            _mapper = mapper;
            _emailService = emailService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllOrders([FromQuery] string? status)
        {
            var query = _context.Orders
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(status))
            {
                query = query.Where(o => o.Status == status);
            }

            var orders = await query.OrderByDescending(o => o.CreatedAt).ToListAsync();
            var orderDTOs = _mapper.Map<List<OrderDTO>>(orders);

            return Ok(orderDTOs);
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Status))
                return BadRequest("Trạng thái không được để trống.");

            try
            {
                var order = await _context.Orders
                    .Include(o => o.OrderDetails)
                        .ThenInclude(od => od.Product)
                    .Include(o => o.User)
                    .FirstOrDefaultAsync(o => o.Id == id);

                if (order == null)
                    return NotFound("Không tìm thấy đơn hàng.");

                // Hoàn trả kho nếu bị huỷ
                if (dto.Status == "Đã huỷ" && order.Status != "Đã huỷ")
                {
                    foreach (var item in order.OrderDetails)
                    {
                        if (item.Product != null)
                        {
                            item.Product.Stock += item.Quantity;
                        }
                    }
                }

                // Cập nhật trạng thái
                order.Status = dto.Status;
                await _context.SaveChangesAsync();

                // ✅ Gửi mail thông báo cho khách
                if (order.User != null && !string.IsNullOrEmpty(order.User.Email))
                {
                    var emailBody = $@"
                        <h3>📢 Cập nhật thông tin đơn hàng</h3>
                        <p>Xin chào <b>{order.ReceiverName}</b>,</p>
                        <p>Đơn hàng của bạn đã được cập nhật trạng thái:</p><p><b style='color:#2c3e50'>{order.Status}</b></p>
                        <br/>
                        <p>RawSaiGon chân thành cảm ơn bạn!</p>";

                    await _emailService.SendEmailAsync(order.User.Email, "Đơn hàng đã được cập nhật", emailBody);
                }

                return Ok(new { message = "✅ Cập nhật trạng thái thành công và đã gửi email cho khách." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Lỗi server: " + ex.Message);
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            var order = await _context.Orders
                .Include(o => o.OrderDetails)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                return NotFound("Không tìm thấy đơn hàng.");

            _context.OrderDetails.RemoveRange(order.OrderDetails);
            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa đơn hàng." });
        }
    }
}
