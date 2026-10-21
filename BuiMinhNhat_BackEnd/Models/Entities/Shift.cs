namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class Shift
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public TimeSpan StartTime { get; set; } = new TimeSpan(8, 0, 0); // 08:00
        public TimeSpan EndTime { get; set; } = new TimeSpan(17, 0, 0);   // 17:00
        public int GracePeriodMinutes { get; set; } = 15; // Cho phép trễ tối đa 15 phút
        public bool IsActive { get; set; } = true;
    }
}
