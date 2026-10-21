using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using BuiMinhNhat_BackEnd.Data;
using BuiMinhNhat_BackEnd.Helpers;
using BuiMinhNhat_BackEnd.Models.Entities;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext kết nối SQL Server
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Server=.\\SQLEXPRESS01;Database=BuiMinhNhat_AttendanceDB;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true";

builder.Services.AddDbContext<MyDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. Cấu hình ASP.NET Core Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireLowercase = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<MyDbContext>()
.AddDefaultTokenProviders();

// 3. Cấu hình JWT Bearer Authentication
var jwtSettings = builder.Configuration.GetSection("JWT");
var secretKey = jwtSettings["Secret"] ?? "SuperSecretKeyForAttendanceAppBuiMinhNhat2026!@#$%^&*()_+";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    options.RequireHttpsMetadata = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidIssuer = jwtSettings["ValidIssuer"] ?? "BuiMinhNhat_AttendanceApp",
        ValidAudience = jwtSettings["ValidAudience"] ?? "BuiMinhNhat_AttendanceClient",
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

// 4. Đăng ký các Helpers & Services
builder.Services.AddScoped<JwtHelper>();
builder.Services.AddScoped<IEmailService, EmailService>();

// 5. Cấu hình CORS mở cho Mobile App, Localhost, Conveyor.cloud
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddControllers();

// 6. OpenAPI (.NET 10)
builder.Services.AddOpenApi();

var app = builder.Build();

// 7. Seed dữ liệu mặc định vào Database
try
{
    using (var scope = app.Services.CreateScope())
    {
        await SeedData.InitializeAsync(scope.ServiceProvider);
    }
}
catch (Exception ex)
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    logger.LogError(ex, "Lỗi xảy ra trong quá trình khởi tạo dữ liệu Database: {Message}", ex.Message);
}

// 8. Cấu hình HTTP Request Pipeline
app.MapOpenApi().AllowAnonymous();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/openapi/v1.json", "BuiMinhNhat Smart Attendance API v1");
    options.RoutePrefix = "swagger";
});

// Phục vụ file tĩnh (ảnh selfie minh chứng tại wwwroot/uploads/attendance)
app.UseStaticFiles();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();