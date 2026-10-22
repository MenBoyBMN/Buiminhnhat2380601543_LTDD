using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Data
{
    public static class SeedData
    {
        public static async Task InitializeAsync(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MyDbContext>();
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

            // Tự động migrate database nếu chưa tồn tại
            await context.Database.MigrateAsync();

            // 1. Tạo các Roles mặc định (Admin, Manager, Employee)
            string[] roles = { "Admin", "Manager", "Employee" };
            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    await roleManager.CreateAsync(new IdentityRole(role));
                }
            }

            // 2. Tạo các Phòng ban mặc định
            if (!await context.Departments.AnyAsync())
            {
                var depts = new List<Department>
                {
                    new Department
                    {
                        Name = "Phòng Công Nghệ Thông Tin (IT)",
                        Description = "Phát triển phần mềm, ứng dụng di động và hạ tầng mạng",
                        OfficeAddress = "280 An Dương Vương, Phường 4, Quận 5, TP.HCM",
                        Latitude = 10.759917,
                        Longitude = 106.682258,
                        RadiusMeters = 300.0
                    },
                    new Department
                    {
                        Name = "Phòng Hành Chính Nhân Sự (HR)",
                        Description = "Quản lý tuyển dụng, nhân sự và phúc lợi",
                        OfficeAddress = "280 An Dương Vương, Phường 4, Quận 5, TP.HCM",
                        Latitude = 10.759917,
                        Longitude = 106.682258,
                        RadiusMeters = 300.0
                    },
                    new Department
                    {
                        Name = "Phòng Kinh Doanh & Marketing",
                        Description = "Kinh doanh, quan hệ khách hàng và tiếp thị",
                        OfficeAddress = "280 An Dương Vương, Phường 4, Quận 5, TP.HCM",
                        Latitude = 10.759917,
                        Longitude = 106.682258,
                        RadiusMeters = 300.0
                    }
                };
                await context.Departments.AddRangeAsync(depts);
                await context.SaveChangesAsync();
            }

            // 3. Tạo các Ca làm việc mặc định
            if (!await context.Shifts.AnyAsync())
            {
                var shifts = new List<Shift>
                {
                    new Shift
                    {
                        Name = "Ca Hành Chính (08:00 - 17:00)",
                        StartTime = new TimeSpan(8, 0, 0),
                        EndTime = new TimeSpan(17, 0, 0),
                        GracePeriodMinutes = 15,
                        IsActive = true
                    },
                    new Shift
                    {
                        Name = "Ca Sáng (07:30 - 11:30)",
                        StartTime = new TimeSpan(7, 30, 0),
                        EndTime = new TimeSpan(11, 30, 0),
                        GracePeriodMinutes = 10,
                        IsActive = true
                    },
                    new Shift
                    {
                        Name = "Ca Chiều (13:00 - 17:30)",
                        StartTime = new TimeSpan(13, 0, 0),
                        EndTime = new TimeSpan(17, 30, 0),
                        GracePeriodMinutes = 10,
                        IsActive = true
                    }
                };
                await context.Shifts.AddRangeAsync(shifts);
                await context.SaveChangesAsync();
            }

            var itDept = await context.Departments.FirstOrDefaultAsync();

            // 4. Tạo User Admin
            var adminUser = await userManager.FindByNameAsync("admin");
            if (adminUser == null)
            {
                adminUser = new ApplicationUser
                {
                    UserName = "admin",
                    Email = "buiminhnhat2910@gmail.com",
                    FullName = "Bùi Minh Nhật (Admin)",
                    Initials = "BMN",
                    EmailConfirmed = true,
                    DepartmentId = itDept?.Id,
                    StreakCount = 10,
                    TotalPoints = 150
                };
                var result = await userManager.CreateAsync(adminUser, "Admin@123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(adminUser, "Admin");
                }
            }

            // 5. Tạo User Manager
            var managerUser = await userManager.FindByNameAsync("manager");
            if (managerUser == null)
            {
                managerUser = new ApplicationUser
                {
                    UserName = "manager",
                    Email = "manager@company.com",
                    FullName = "Nguyễn Văn Quản Lý",
                    Initials = "NQL",
                    EmailConfirmed = true,
                    DepartmentId = itDept?.Id,
                    StreakCount = 5,
                    TotalPoints = 80
                };
                var result = await userManager.CreateAsync(managerUser, "Manager@123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(managerUser, "Manager");
                }
            }

            // 6. Tạo User Employee (Nhân viên)
            var empUser = await userManager.FindByNameAsync("nhanvien1");
            if (empUser == null)
            {
                empUser = new ApplicationUser
                {
                    UserName = "nhanvien1",
                    Email = "nhanvien1@company.com",
                    FullName = "Trần Thị Thu Thảo",
                    Initials = "TTT",
                    EmailConfirmed = true,
                    DepartmentId = itDept?.Id,
                    StreakCount = 7,
                    TotalPoints = 120,
                    LastCheckInDate = DateTime.Now.Date.AddDays(-1)
                };
                var result = await userManager.CreateAsync(empUser, "User@123");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(empUser, "Employee");
                }
            }
        }
    }
}
