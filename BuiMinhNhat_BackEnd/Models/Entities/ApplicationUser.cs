using Microsoft.AspNetCore.Identity;

namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class ApplicationUser : IdentityUser
    {
        public string FullName { get; set; } = string.Empty;
        public string? Initials { get; set; }
        public int? DepartmentId { get; set; }
        public Department? Department { get; set; }
        public string? OtpCode { get; set; }
        public DateTime? OtpExpiry { get; set; }
        public int StreakCount { get; set; } = 0;
        public int TotalPoints { get; set; } = 0;
        public DateTime? LastCheckInDate { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
