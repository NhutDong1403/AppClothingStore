using AutoMapper;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using System;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ClothingStoreAPI.Data;
using Microsoft.EntityFrameworkCore;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class VoucherController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public VoucherController(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        // GET: api/voucher
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var vouchers = await _context.Vouchers.ToListAsync();
            return Ok(_mapper.Map<List<VoucherDto>>(vouchers));
        }

        // POST: api/voucher
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] VoucherDto dto)
        {
            var voucher = _mapper.Map<Voucher>(dto);
            _context.Vouchers.Add(voucher);
            await _context.SaveChangesAsync();

            // Sau khi SaveChanges, voucher.Id sẽ có giá trị đúng (tự tăng từ DB)
            return Ok(_mapper.Map<VoucherDto>(voucher)); // <- Quan trọng!
        }

        // GET: api/voucher/SALE20
        [HttpGet("{code}")]
        public async Task<IActionResult> GetByCode(string code)
        {
            var voucher = await _context.Vouchers
                .FirstOrDefaultAsync(v => v.Code.ToLower() == code.ToLower());

            if (voucher == null || voucher.ExpiryDate < DateTime.UtcNow)
                return NotFound("Voucher không hợp lệ hoặc đã hết hạn.");

            return Ok(_mapper.Map<VoucherDto>(voucher));
        }
        // DETLE
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var voucher = await _context.Vouchers.FindAsync(id);
            if (voucher == null)
                return NotFound("Voucher không tồn tại.");

            _context.Vouchers.Remove(voucher);
            await _context.SaveChangesAsync();

            return NoContent(); // 204
        }
        // PUT: api/voucher/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] VoucherDto dto)
        {
            var existingVoucher = await _context.Vouchers.FindAsync(id);
            if (existingVoucher == null)
                return NotFound("Voucher không tồn tại.");

            // Ánh xạ DTO sang entity (cập nhật dữ liệu)
            _mapper.Map(dto, existingVoucher);

            await _context.SaveChangesAsync();

            return NoContent(); // 204
        }   
    }
}
