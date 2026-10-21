namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class AttendanceRecord
    {
        public int Id { get; set; }
        
        public string UserId { get; set; } = string.Empty;
        public ApplicationUser? User { get; set; }

        public int? ShiftId { get; set; }
        public Shift? Shift { get; set; }

        public DateTime CheckInTime { get; set; } = DateTime.Now;
        public DateTime? CheckOutTime { get; set; }

        // GPS Check-in
        public double CheckInLatitude { get; set; }
        public double CheckInLongitude { get; set; }
        public double DistanceMeters { get; set; } // Khoảng cách tới văn phòng
        public bool IsWithinGeofence { get; set; }

        // QR Code & Minh chứng ảnh
        public string? QrTokenUsed { get; set; }
        public string? PhotoUrl { get; set; } // Đường dẫn ảnh selfie minh chứng

        // Tính năng mới: Mood & Energy Check-in + Gamification
        public string? Mood { get; set; } // "Happy", "Energetic", "Neutral", "Tired", "Stressed"
        public string? Note { get; set; }
        public string Status { get; set; } = "OnTime"; // "OnTime", "Late", "Overtime", "EarlyLeave"
        public int PointsEarned { get; set; } = 10; // Điểm chuyên cần tích lũy
    }
}
