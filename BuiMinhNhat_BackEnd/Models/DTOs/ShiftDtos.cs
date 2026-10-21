using System.ComponentModel.DataAnnotations;

namespace BuiMinhNhat_BackEnd.Models.DTOs
{
    public class ShiftDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string StartTime { get; set; } = "08:00";
        public string EndTime { get; set; } = "17:00";
        public int GracePeriodMinutes { get; set; }
        public bool IsActive { get; set; }
    }

    public class CreateUpdateShiftDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string StartTime { get; set; } = "08:00"; // Định dạng "HH:mm"

        [Required]
        public string EndTime { get; set; } = "17:00";   // Định dạng "HH:mm"

        public int GracePeriodMinutes { get; set; } = 15;
        public bool IsActive { get; set; } = true;
    }
}
