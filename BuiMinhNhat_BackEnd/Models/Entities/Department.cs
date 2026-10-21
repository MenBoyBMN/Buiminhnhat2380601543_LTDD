namespace BuiMinhNhat_BackEnd.Models.Entities
{
    public class Department
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? OfficeAddress { get; set; }
        
        // Vị trí GPS văn phòng để kiểm tra bán kính (Geofencing)
        public double Latitude { get; set; } = 10.762622; // Mặc định TP.HCM
        public double Longitude { get; set; } = 106.660172;
        public double RadiusMeters { get; set; } = 200.0; // Bán kính cho phép (mét)

        public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
    }
}
