namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class QrSession
    {
        public int Id { get; set; }
        public string TokenCode { get; set; } = string.Empty; // Mã token động ngẫu nhiên
        public int? ShiftId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiresAt { get; set; } = DateTime.UtcNow.AddSeconds(60); // Đổi mỗi 60 giây
        public string? CreatedByUserId { get; set; }
        public bool IsActive => DateTime.UtcNow <= ExpiresAt;
    }
}
