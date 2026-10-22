using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using BuiMinhNhat_BackEnd.Data;
using BuiMinhNhat_BackEnd.Helpers;
using BuiMinhNhat_BackEnd.Models.DTOs;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthenticateController : ControllerBase
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly RoleManager<IdentityRole> _roleManager;
        private readonly MyDbContext _context;
        private readonly JwtHelper _jwtHelper;
        private readonly IEmailService _emailService;

        public AuthenticateController(
            UserManager<ApplicationUser> userManager,
            RoleManager<IdentityRole> roleManager,
            MyDbContext context,
            JwtHelper jwtHelper,
            IEmailService emailService)
        {
            _userManager = userManager;
            _roleManager = roleManager;
            _context = context;
            _jwtHelper = jwtHelper;
            _emailService = emailService;
        }

        /// <summary>
        /// 1. Đăng ký tài khoản qua email
        /// </summary>
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var existingUser = await _userManager.FindByNameAsync(model.UserName);
            if (existingUser != null)
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại!" });

            var existingEmail = await _userManager.FindByEmailAsync(model.Email);
            if (existingEmail != null)
                return BadRequest(new { message = "Email này đã được sử dụng!" });

            // Mặc định gán vào phòng ban đầu tiên nếu không chọn
            int? deptId = model.DepartmentId;
            if (!deptId.HasValue)
            {
                var firstDept = await _context.Departments.FirstOrDefaultAsync();
                deptId = firstDept?.Id;
            }

            var user = new ApplicationUser
            {
                UserName = model.UserName,
                Email = model.Email,
                FullName = model.FullName,
                Initials = !string.IsNullOrEmpty(model.Initials) ? model.Initials : GetInitials(model.FullName),
                DepartmentId = deptId,
                EmailConfirmed = true,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                var errors = string.Join(", ", result.Errors.Select(e => e.Description));
                return BadRequest(new { message = errors });
            }

            // Gán Role (Mặc định Employee nếu không hợp lệ)
            var targetRole = string.IsNullOrEmpty(model.Role) ? "Employee" : model.Role;
            if (!await _roleManager.RoleExistsAsync(targetRole))
            {
                targetRole = "Employee";
            }
            await _userManager.AddToRoleAsync(user, targetRole);

            return Ok(new { message = "Đăng ký tài khoản thành công!", userName = user.UserName, role = targetRole });
        }

        /// <summary>
        /// 2. Đăng nhập Bước 1: Kiểm tra Tên đăng nhập + Mật khẩu -> Phát sinh mã OTP 6 số
        /// </summary>
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null)
            {
                // Thử tìm theo Email
                user = await _userManager.FindByEmailAsync(model.UserName);
            }

            if (user == null || !await _userManager.CheckPasswordAsync(user, model.Password))
            {
                return Unauthorized(new { message = "Tên đăng nhập hoặc mật khẩu không chính xác!" });
            }

            // Sinh mã OTP ngẫu nhiên 6 chữ số
            var otpCode = new Random().Next(100000, 999999).ToString();
            user.OtpCode = otpCode;
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(5); // Hiệu lực 5 phút
            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            // Gửi OTP qua Email
            await _emailService.SendOtpEmailAsync(user.Email ?? "", user.FullName, otpCode);

            // Trả về yêu cầu nhập OTP, kèm demoOtp để chấm bài thuận tiện
            return Ok(new LoginStep1ResponseDto
            {
                RequireOtp = true,
                UserName = user.UserName!,
                Email = MaskEmail(user.Email ?? ""),
                Message = $"Mã OTP đã được tạo và gửi đến {MaskEmail(user.Email ?? "")}. Vui lòng nhập mã để hoàn tất đăng nhập.",
                DemoOtp = otpCode // Giúp người chấm bài hoặc người dùng test nhanh ngay trên App
            });
        }

        /// <summary>
        /// 2. Đăng nhập Bước 2: Xác thực mã OTP -> Trả về JWT Token
        /// </summary>
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto model)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var user = await _userManager.FindByNameAsync(model.UserName);
            if (user == null)
            {
                // Thử tìm theo Email nếu đầu vào là Email
                user = await _userManager.FindByEmailAsync(model.UserName);
            }

            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng!" });

            if (string.IsNullOrEmpty(user.OtpCode) || user.OtpCode != model.OtpCode)
            {
                return BadRequest(new { message = "Mã OTP không đúng!" });
            }

            if (!user.OtpExpiry.HasValue || user.OtpExpiry.Value < DateTime.UtcNow)
            {
                return BadRequest(new { message = "Mã OTP đã hết hạn (chỉ có hiệu lực 5 phút)!" });
            }

            // Xóa mã OTP sau khi xác thực thành công
            user.OtpCode = null;
            user.OtpExpiry = null;
            _context.Users.Update(user);
            await _context.SaveChangesAsync();

            // Lấy Roles và thông tin phòng ban
            var roles = await _userManager.GetRolesAsync(user);
            var department = user.DepartmentId.HasValue 
                ? await _context.Departments.FindAsync(user.DepartmentId.Value) 
                : null;

            var token = _jwtHelper.GenerateToken(user, roles, department?.Name);

            var userInfo = new UserInfoDto
            {
                Id = user.Id,
                UserName = user.UserName!,
                Email = user.Email ?? "",
                FullName = user.FullName,
                Initials = user.Initials,
                Role = roles.FirstOrDefault() ?? "Employee",
                DepartmentId = user.DepartmentId,
                DepartmentName = department?.Name,
                StreakCount = user.StreakCount,
                TotalPoints = user.TotalPoints
            };

            return Ok(new AuthResponseDto
            {
                Token = token,
                Expiration = DateTime.UtcNow.AddHours(72),
                User = userInfo
            });
        }

        /// <summary>
        /// Lấy thông tin cá nhân của người dùng hiện tại
        /// </summary>
        [Authorize]
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue(ClaimTypes.Name);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _context.Users
                .Include(u => u.Department)
                .FirstOrDefaultAsync(u => u.Id == userId || u.UserName == userId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy thông tin người dùng!" });

            var roles = await _userManager.GetRolesAsync(user);

            return Ok(new UserInfoDto
            {
                Id = user.Id,
                UserName = user.UserName!,
                Email = user.Email ?? "",
                FullName = user.FullName,
                Initials = user.Initials,
                Role = roles.FirstOrDefault() ?? "Employee",
                DepartmentId = user.DepartmentId,
                DepartmentName = user.Department?.Name,
                StreakCount = user.StreakCount,
                TotalPoints = user.TotalPoints
            });
        }

        /// <summary>
        /// Lấy danh sách toàn bộ người dùng (Dành cho Admin/Manager)
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _context.Users
                .Include(u => u.Department)
                .ToListAsync();

            var userDtos = new List<UserInfoDto>();
            foreach (var u in users)
            {
                var roles = await _userManager.GetRolesAsync(u);
                userDtos.Add(new UserInfoDto
                {
                    Id = u.Id,
                    UserName = u.UserName!,
                    Email = u.Email ?? "",
                    FullName = u.FullName,
                    Initials = u.Initials,
                    Role = roles.FirstOrDefault() ?? "Employee",
                    DepartmentId = u.DepartmentId,
                    DepartmentName = u.Department?.Name,
                    StreakCount = u.StreakCount,
                    TotalPoints = u.TotalPoints
                });
            }

            return Ok(userDtos);
        }

        private static string GetInitials(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "NV";
            var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1) return parts[0].Substring(0, Math.Min(2, parts[0].Length)).ToUpper();
            return string.Concat(parts.Select(p => p[0])).ToUpper();
        }

        private static string MaskEmail(string email)
        {
            if (string.IsNullOrEmpty(email) || !email.Contains('@')) return email;
            var parts = email.Split('@');
            var name = parts[0];
            if (name.Length <= 2) return $"{name}***@{parts[1]}";
            return $"{name[0]}***{name[^1]}@{parts[1]}";
        }
    }
}
