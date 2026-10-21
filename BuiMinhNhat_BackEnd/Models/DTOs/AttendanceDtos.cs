using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace BuiMinhNhat_BackEnd.Models.DTOs
{
    public class CheckInDto
    {
        public int? ShiftId { get; set; }

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

        public string? QrToken { get; set; }

        public string? Mood { get; set; } // "Happy", "Energetic", "Neutral", "Tired", "Stressed"

        public string? Note { get; set; }

        // Ảnh chụp selfie minh chứng gửi dạng multipart
        public IFormFile? Photo { get; set; }
    }

    public class CheckOutDto
    {
        public int? AttendanceRecordId { get; set; }
        public string? Note { get; set; }
    }

    public class AttendanceRecordDto
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? DepartmentName { get; set; }
        public string? ShiftName { get; set; }

        public DateTime CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }

        public double CheckInLatitude { get; set; }
        public double CheckInLongitude { get; set; }
        public double DistanceMeters { get; set; }
        public bool IsWithinGeofence { get; set; }

        public string? QrTokenUsed { get; set; }
        public string? PhotoUrl { get; set; }

        public string? Mood { get; set; }
        public string? Note { get; set; }
        public string Status { get; set; } = string.Empty;
        public int PointsEarned { get; set; }
    }

    public class LeaderboardItemDto
    {
        public int Rank { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? DepartmentName { get; set; }
        public int StreakCount { get; set; }
        public int TotalPoints { get; set; }
    }

    public class UpdateAttendanceDto
    {
        public DateTime CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public string Status { get; set; } = "OnTime";
        public string? Note { get; set; }
    }
}
