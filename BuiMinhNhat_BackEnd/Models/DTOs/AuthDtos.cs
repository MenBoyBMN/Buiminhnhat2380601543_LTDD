using System.ComponentModel.DataAnnotations;

namespace BuiMinhNhat_BackEnd.Models.DTOs
{
    public class RegisterDto
    {
        [Required]
        public string UserName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        public string? Initials { get; set; }
        public int? DepartmentId { get; set; }
        public string Role { get; set; } = "Employee"; // Admin, Manager, Employee
    }

    public class LoginDto
    {
        [Required]
        public string UserName { get; set; } = string.Empty;

        [Required]
        public string Password { get; set; } = string.Empty;
    }

    public class VerifyOtpDto
    {
        [Required]
        public string UserName { get; set; } = string.Empty;

        [Required]
        public string OtpCode { get; set; } = string.Empty;
    }

    public class LoginStep1ResponseDto
    {
        public bool RequireOtp { get; set; } = true;
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string DemoOtp { get; set; } = string.Empty; // Trả về để demo chấm bài mượt mà
    }

    public class AuthResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public DateTime Expiration { get; set; }
        public UserInfoDto User { get; set; } = null!;
    }

    public class UserInfoDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Initials { get; set; }
        public string Role { get; set; } = string.Empty;
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int StreakCount { get; set; }
        public int TotalPoints { get; set; }
    }
}
