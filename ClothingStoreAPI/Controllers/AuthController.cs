using ClothingStoreAPI.Data;
using ClothingStoreAPI.DTOs;
using ClothingStoreAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ClothingStoreAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(ApplicationDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // ✅ API Đăng nhập hỗ trợ cả `Username` hoặc `Email`
        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginRequestDTO loginDTO) // ✅ Đổi từ `LoginRequesDTO` sang `LoginRequestDTO`
        {
            var user = await _context.Users.FirstOrDefaultAsync(u =>
                u.Username == loginDTO.Username || u.Email == loginDTO.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(loginDTO.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "❌ Tên đăng nhập hoặc mật khẩu không đúng!" });
            }

            var token = GenerateJwtToken(user);

            return Ok(new
            {
                message = "✅ Đăng nhập thành công!",
                token,
                user = new UserDTO
                {
                    Id = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    Role = user.Role
                }
            });
        }

        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var jwtSecretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("Missing JWT Secret Key");

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey));

            var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()), // ✅ Sửa đổi ở đây!
        new Claim(ClaimTypes.Name, user.Username),
        new Claim(ClaimTypes.Role, user.Role),
        // Bạn vẫn có thể thêm thêm claim nếu muốn
        new Claim("UserId", user.Id.ToString()) // 👈 Giữ lại nếu bạn dùng ở nơi khác
    };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(2),
                Issuer = jwtSettings["Issuer"],
                Audience = jwtSettings["Audience"],
                SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256Signature),
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }



        [HttpPost("register")]
        public async Task<ActionResult<UserDTO>> RegisterUser(CreateUserDTO createUserDTO)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (string.IsNullOrWhiteSpace(createUserDTO.Password))
                return BadRequest(new { message = "❌ Mật khẩu không được để trống!" });

            // Kiểm tra độ mạnh của mật khẩu
            if (createUserDTO.Password.Length < 8 || !createUserDTO.Password.Any(char.IsDigit))
            {
                return BadRequest(new { message = "❌ Mật khẩu phải có ít nhất 8 ký tự và chứa số!" });
            }

            // Kiểm tra username/email trùng
            var isUsernameUsed = await _context.Users.AnyAsync(u => u.Username == createUserDTO.Username);
            if (isUsernameUsed)
                return Conflict(new { message = "❌ Tên đăng nhập đã tồn tại!" });

            var isEmailUsed = await _context.Users.AnyAsync(u => u.Email == createUserDTO.Email);
            if (isEmailUsed)
                return Conflict(new { message = "❌ Email đã tồn tại!" });

            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(createUserDTO.Password);

            var user = new User
            {
                Username = createUserDTO.Username,
                Email = createUserDTO.Email,
                PasswordHash = hashedPassword,
                Role = "User"
            };

            try
            {
                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                var userDto = new UserDTO
                {
                    Id = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    Role = user.Role
                };

                return CreatedAtAction(nameof(RegisterUser), new { id = user.Id }, userDto);
            }
            catch (Exception ex)
            {
                // Có thể log lỗi tại đây (vd: _logger.LogError(ex, "Lỗi khi đăng ký"))
                return StatusCode(500, new { message = $"❌ Có lỗi xảy ra: {ex.Message}" });
            }
        }


        [HttpPost("change-password")]
        [Authorize] // Người dùng phải đăng nhập
        public async Task<IActionResult> ChangePassword(ChangePasswordDTO request)
        {
            var userId = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "❌ Không tìm thấy User ID!" });

            var user = await _context.Users.FindAsync(int.Parse(userId));
            if (user == null)
                return NotFound(new { message = "❌ Người dùng không tồn tại!" });

            // Kiểm tra mật khẩu cũ
            if (!BCrypt.Net.BCrypt.Verify(request.OldPassword, user.PasswordHash))
                return BadRequest(new { message = "❌ Mật khẩu cũ không đúng!" });

            // Kiểm tra mật khẩu mới có giống mật khẩu cũ không
            if (BCrypt.Net.BCrypt.Verify(request.NewPassword, user.PasswordHash))
                return BadRequest(new { message = "❌ Mật khẩu mới không được trùng với mật khẩu cũ!" });

            // Kiểm tra mật khẩu mới hợp lệ
            if (request.NewPassword.Length < 8 || !request.NewPassword.Any(char.IsDigit))
                return BadRequest(new { message = "❌ Mật khẩu mới phải có ít nhất 8 ký tự và chứa số!" });

            // Kiểm tra mật khẩu mới khớp với xác nhận
            if (request.NewPassword != request.ConfirmPassword)
                return BadRequest(new { message = "❌ Mật khẩu mới không trùng khớp với xác nhận!" });

            // Mã hóa mật khẩu mới và lưu vào database
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            await _context.SaveChangesAsync();

            return Ok(new { message = "✅ Đã thay đổi mật khẩu thành công!" });
        }



    }
}
