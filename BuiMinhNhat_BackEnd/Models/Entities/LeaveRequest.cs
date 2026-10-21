namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class LeaveRequest
    {
        public int Id { get; set; }

        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }

        public string LeaveType { get; set; } = "Annual"; // "Annual" (Nghỉ phép năm), "Sick" (Nghỉ ốm), "Unpaid" (Nghỉ không lương), "Personal" (Việc riêng)
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Reason { get; set; } = string.Empty;

        public string Status { get; set; } = "Pending"; // "Pending", "Approved", "Rejected"
        public string? ReviewedByUserId { get; set; }
        public string? ReviewNote { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? ReviewedAt { get; set; }
    }
}
