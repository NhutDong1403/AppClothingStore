using AutoMapper;
using ClothingStoreAPI.Data;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using ClothingStoreAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class OrderController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;
        private readonly IEmailService _emailService;

        public OrderController(ApplicationDbContext context, IMapper mapper, IEmailService emailService)
        {
            _context = context;
            _mapper = mapper;
            _emailService = emailService;
        }

        private int GetUserIdFromToken()
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdStr, out int userId) ? userId : 0;
        }

        [HttpGet("user")]
        public async Task<ActionResult<List<OrderDTO>>> GetOrdersByUser()
        {
            int userId = GetUserIdFromToken();
            if (userId == 0) return Unauthorized();

            var orders = await _context.Orders
                .Where(o => o.UserId == userId)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .ToListAsync();

            return Ok(_mapper.Map<List<OrderDTO>>(orders));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<OrderDTO>> GetOrder(int id)
        {
            int userId = GetUserIdFromToken();
            if (userId == 0) return Unauthorized();

            var order = await _context.Orders
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product)
                .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId);

            if (order == null)
                return NotFound("Không tìm thấy đơn hàng của bạn.");

            return Ok(_mapper.Map<OrderDTO>(order));
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderDTO dto)
        {
            var currentUserIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("id");
            if (!int.TryParse(currentUserIdStr, out int currentUserId))
                return Unauthorized();

            var productIds = dto.Items.Select(i => i.ProductId).Distinct().ToList();
            var products = await _context.Products
                .Where(p => productIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id);

            var orderDetails = new List<OrderDetail>();
            decimal originalAmount = 0;

            foreach (var item in dto.Items)
            {
                if (!products.ContainsKey(item.ProductId))
                    return BadRequest($"Sản phẩm không tồn tại (ID: {item.ProductId})");

                var product = products[item.ProductId];

                if (product.Stock < item.Quantity)
                    return BadRequest($"Sản phẩm '{product.Name}' không đủ hàng trong kho.");

                product.Stock -= item.Quantity;
                product.SoldCount += item.Quantity; // ✅ thêm dòng này

                orderDetails.Add(new OrderDetail
                {
                    ProductId = item.ProductId,
                    Quantity = item.Quantity,
                    UnitPrice = item.Price
                });

                originalAmount += item.Price * item.Quantity;
            }


            decimal discountAmount = 0;
            decimal discountPercent = 0;

            if (!string.IsNullOrEmpty(dto.VoucherCode))
            {
                var voucher = await _context.Vouchers
                    .FirstOrDefaultAsync(v => v.Code.ToLower() == dto.VoucherCode.ToLower());

                if (voucher != null && voucher.ExpiryDate > DateTime.UtcNow)
                {
                    discountPercent = voucher.DiscountPercent;
                    discountAmount = originalAmount * discountPercent / 100;
                }
            }

            var order = new Order
            {
                CreatedAt = DateTime.UtcNow,
                OrderDate = DateTime.Now, // ✅ Gán ngày đặt hàng hiện tại
                UserId = currentUserId,
                ReceiverName = dto.ReceiverName,
                Phone = dto.Phone,
                Address = dto.Address,
                Note = dto.Note,
                Status = dto.Status ?? "Đang xử lý",
                VoucherCode = dto.VoucherCode,
                PaymentMethod = dto.PaymentMethod,
                Discount = discountPercent,
                OriginalAmount = originalAmount,
                TotalAmount = originalAmount - discountAmount,
                OrderDetails = orderDetails
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // ✅ Tạo voucher tặng khách
            var voucherCode = "SALE" + Guid.NewGuid().ToString("N")[..6].ToUpper();
            var giftVoucher = new Voucher
            {
                Code = voucherCode,
                DiscountPercent = 10,
                ExpiryDate = DateTime.UtcNow.AddDays(30)
            };
            _context.Vouchers.Add(giftVoucher);
            await _context.SaveChangesAsync();

            // ✅ Gửi email xác nhận
            var user = await _context.Users.FindAsync(currentUserId);
            if (user != null && !string.IsNullOrEmpty(user.Email))
            {
                var emailBody = $@"
                    <h3>🛍️ Đặt hàng thành công tại Clothing Shop</h3>
                    <p>Xin chào <b>{order.ReceiverName}</b>,</p>
                    <p>Bạn đã đặt hàng thành công. Mã đơn hàng: <b>#{order.Id}</b></p>
                    <p>Trạng thái: <b>{order.Status}</b></p>
                    <p>Tổng tiền: <b>{order.TotalAmount:N0} VNĐ</b></p>
                    <p>Phương thức thanh toán: {order.PaymentMethod}</p>

                    <hr/>
                    <h4>🎁 Quà tặng đặc biệt:</h4>
                    <p>Bạn nhận được mã giảm giá <b style='color:green'>{giftVoucher.Code}</b> giảm <b>{giftVoucher.DiscountPercent}%</b> cho lần mua tiếp theo.</p>
                    <p>Mã có hiệu lực đến: <b>{giftVoucher.ExpiryDate:dd/MM/yyyy}</b></p>

                    <br/><i>Chúng tôi sẽ xử lý đơn hàng trong thời gian sớm nhất. Cảm ơn bạn!</i>
                ";

                await _emailService.SendEmailAsync(user.Email, "Xác nhận đơn hàng & Quà tặng từ Clothing Shop", emailBody);
            }

            return Ok(new { order.Id });
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateOrder(int id, [FromBody] Order updateOrder)
        {
            var existingOrder = await _context.Orders
                .Include(o => o.User)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (existingOrder == null)
                return NotFound("Không tìm thấy đơn hàng.");

            existingOrder.Status = updateOrder.Status;
            existingOrder.ReceiverName = updateOrder.ReceiverName;
            existingOrder.Phone = updateOrder.Phone;
            existingOrder.Address = updateOrder.Address;
            existingOrder.Note = updateOrder.Note;

            _context.Entry(existingOrder).State = EntityState.Modified;
            await _context.SaveChangesAsync();

            // ✅ Gửi email thông báo cập nhật đơn hàng
            if (existingOrder.User != null && !string.IsNullOrEmpty(existingOrder.User.Email))
            {
                var emailBody = $@"
                    <h3>📦 Cập nhật đơn hàng #{existingOrder.Id}</h3>
                    <p>Xin chào <b>{existingOrder.ReceiverName}</b>,</p>
                    <p>Đơn hàng của bạn đã được cập nhật trạng thái:</p>
                    <p><b>{existingOrder.Status}</b></p>
                    <br/><i>Cảm ơn bạn đã mua sắm tại Clothing Shop.</i>
                ";

                await _emailService.SendEmailAsync(existingOrder.User.Email, "Cập nhật đơn hàng từ Clothing Shop", emailBody);
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            int userId = GetUserIdFromToken();
            if (userId == 0) return Unauthorized();

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId);
            if (order == null)
                return NotFound("Không tìm thấy đơn hàng.");

            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
