using System.ComponentModel.DataAnnotations;

namespace BuiMinhNhat_BackEnd.Models.DTOs
{
    public class CreateLeaveRequestDto
    {
        [Required]
        public string LeaveType { get; set; } = "Annual"; // "Annual", "Sick", "Unpaid", "Personal"

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        [Required]
        public string Reason { get; set; } = string.Empty;
    }

    public class LeaveRequestDto
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? DepartmentName { get; set; }
        public string LeaveType { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string Status { get; set; } = "Pending";
        public string? ReviewedBy { get; set; }
        public string? ReviewNote { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ReviewedAt { get; set; }
    }

    public class ReviewLeaveRequestDto
    {
        [Required]
        public string Status { get; set; } = "Approved"; // "Approved" or "Rejected"
        public string? ReviewNote { get; set; }
    }

    public class QrSessionDto
    {
        public string TokenCode { get; set; } = string.Empty;
        public int? ShiftId { get; set; }
        public DateTime ExpiresAt { get; set; }
        public int RemainingSeconds { get; set; }
    }
}
