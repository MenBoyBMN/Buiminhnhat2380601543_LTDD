using System.ComponentModel.DataAnnotations;

namespace BuiMinhNhat_BackEnd.Models.DTOs
{
    public class DepartmentDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? OfficeAddress { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double RadiusMeters { get; set; }
        public int UserCount { get; set; }
    }

    public class CreateUpdateDepartmentDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? OfficeAddress { get; set; }
        public double Latitude { get; set; } = 10.759917;
        public double Longitude { get; set; } = 106.682258;
        public double RadiusMeters { get; set; } = 300.0;
    }
}
