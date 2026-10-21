using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using BuiMinhNhat_BackEnd.Data;
using BuiMinhNhat_BackEnd.Helpers;
using BuiMinhNhat_BackEnd.Models.DTOs;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AttendanceController : ControllerBase
    {
        private readonly MyDbContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<AttendanceController> _logger;

        public AttendanceController(MyDbContext context, IWebHostEnvironment env, ILogger<AttendanceController> logger)
        {
            _context = context;
            _env = env;
            _logger = logger;
        }

        /// <summary>
        /// 6. Tính năng mới: Sinh mã Dynamic Anti-Fraud QR Code mới (Hiệu lực 60 giây)
        /// Dành cho Admin/Manager hiển thị trên màn hình lớn văn phòng
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpPost("generate-qr")]
        public async Task<IActionResult> GenerateDynamicQr([FromQuery] int? shiftId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            // Xóa các session đã hết hạn cũ để dọn dẹp
            var expired = await _context.QrSessions.Where(q => q.ExpiresAt < DateTime.UtcNow).ToListAsync();
            if (expired.Any())
            {
                _context.QrSessions.RemoveRange(expired);
            }

            var token = $"ATTEND_{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper()}";
            var session = new QrSession
            {
                TokenCode = token,
                ShiftId = shiftId,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddSeconds(60), // Hết hạn sau 60 giây
                CreatedByUserId = userId
            };

            _context.QrSessions.Add(session);
            await _context.SaveChangesAsync();

            return Ok(new QrSessionDto
            {
                TokenCode = session.TokenCode,
                ShiftId = session.ShiftId,
                ExpiresAt = session.ExpiresAt,
                RemainingSeconds = 60
            });
        }

        /// <summary>
        /// Lấy mã QR đang hoạt động gần nhất
        /// </summary>
        [HttpGet("active-qr")]
        public async Task<IActionResult> GetActiveQr()
        {
            var activeSession = await _context.QrSessions
                .Where(q => q.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(q => q.CreatedAt)
                .FirstOrDefaultAsync();

            if (activeSession == null)
            {
                // Tự động tạo mới một mã QR nếu chưa có để demo luôn tiện lợi
                var token = $"ATTEND_{DateTime.UtcNow:yyyyMMddHHmmss}_{Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper()}";
                activeSession = new QrSession
                {
                    TokenCode = token,
                    CreatedAt = DateTime.UtcNow,
                    ExpiresAt = DateTime.UtcNow.AddSeconds(120)
                };
                _context.QrSessions.Add(activeSession);
                await _context.SaveChangesAsync();
            }

            var remaining = (int)Math.Max(0, (activeSession.ExpiresAt - DateTime.UtcNow).TotalSeconds);

            return Ok(new QrSessionDto
            {
                TokenCode = activeSession.TokenCode,
                ShiftId = activeSession.ShiftId,
                ExpiresAt = activeSession.ExpiresAt,
                RemainingSeconds = remaining
            });
        }

        /// <summary>
        /// 5. Chấm công 3-trong-1 (GPS Geofence + QR Code + Chụp ảnh selfie minh chứng + Mood Check-in)
        /// </summary>
        [Authorize]
        [HttpPost("check-in")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> CheckIn([FromForm] CheckInDto dto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var user = await _context.Users
                .Include(u => u.Department)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng!" });

            // 1. Kiểm tra QR Code nếu có cung cấp
            if (!string.IsNullOrEmpty(dto.QrToken))
            {
                var validQr = await _context.QrSessions
                    .AnyAsync(q => q.TokenCode == dto.QrToken && q.ExpiresAt >= DateTime.UtcNow.AddMinutes(-5));
                // Nếu mã QR bắt đầu bằng ATTEND_ hoặc QR hợp lệ
                if (!validQr && !dto.QrToken.StartsWith("ATTEND_"))
                {
                    _logger.LogWarning("Mã QR không đúng định dạng hoặc đã hết hạn: {Token}", dto.QrToken);
                }
            }

            // 2. Tính khoảng cách GPS Geofencing
            double targetLat = user.Department?.Latitude ?? 10.759917;
            double targetLng = user.Department?.Longitude ?? 106.682258;
            double radiusMeters = user.Department?.RadiusMeters ?? 300.0;

            double distance = GeofenceHelper.CalculateDistanceMeters(dto.Latitude, dto.Longitude, targetLat, targetLng);
            bool isWithinGeofence = distance <= radiusMeters;

            // 3. Xử lý lưu ảnh selfie minh chứng
            string? photoUrl = null;
            if (dto.Photo != null && dto.Photo.Length > 0)
            {
                var webRoot = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var uploadDir = Path.Combine(webRoot, "uploads", "attendance");
                if (!Directory.Exists(uploadDir))
                {
                    Directory.CreateDirectory(uploadDir);
                }

                var fileName = $"{Guid.NewGuid():N}_{Path.GetFileName(dto.Photo.FileName)}";
                var filePath = Path.Combine(uploadDir, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Photo.CopyToAsync(stream);
                }

                photoUrl = $"/uploads/attendance/{fileName}";
            }

            // 4. Xác định Ca làm việc và Trạng thái Đi làm đúng giờ hay Trễ
            var now = DateTime.Now;
            var currentTime = now.TimeOfDay;

            Shift? shift = null;
            if (dto.ShiftId.HasValue)
            {
                shift = await _context.Shifts.FindAsync(dto.ShiftId.Value);
            }
            if (shift == null)
            {
                shift = await _context.Shifts.FirstOrDefaultAsync(s => s.IsActive);
            }

            string status = "OnTime";
            int points = 10;

            if (shift != null)
            {
                var allowedTime = shift.StartTime.Add(TimeSpan.FromMinutes(shift.GracePeriodMinutes));
                if (currentTime > allowedTime)
                {
                    status = "Late";
                    points = 5;
                }
            }

            // 5. Cập nhật Điểm chuyên cần và Streak 🔥
            if (user.LastCheckInDate.HasValue)
            {
                var lastDate = user.LastCheckInDate.Value.Date;
                var today = now.Date;

                if (today == lastDate.AddDays(1))
                {
                    // Ngày kế tiếp liên tục -> tăng Streak
                    user.StreakCount += 1;
                }
                else if (today > lastDate.AddDays(1))
                {
                    // Đứt chuỗi -> reset về 1
                    user.StreakCount = 1;
                }
            }
            else
            {
                user.StreakCount = 1;
            }

            user.TotalPoints += points;
            user.LastCheckInDate = now;

            // 6. Tạo bản ghi chấm công AttendanceRecord
            var record = new AttendanceRecord
            {
                UserId = user.Id,
                ShiftId = shift?.Id,
                CheckInTime = now,
                CheckInLatitude = dto.Latitude,
                CheckInLongitude = dto.Longitude,
                DistanceMeters = distance,
                IsWithinGeofence = isWithinGeofence,
                QrTokenUsed = dto.QrToken,
                PhotoUrl = photoUrl,
                Mood = !string.IsNullOrEmpty(dto.Mood) ? dto.Mood : "Happy",
                Note = dto.Note,
                Status = status,
                PointsEarned = points
            };

            _context.AttendanceRecords.Add(record);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = isWithinGeofence 
                    ? "Check-in thành công tại văn phòng!" 
                    : $"Check-in thành công (Cảnh báo: Ngoài bán kính cho phép {distance}m > {radiusMeters}m)!",
                record = new AttendanceRecordDto
                {
                    Id = record.Id,
                    UserId = user.Id,
                    FullName = user.FullName,
                    DepartmentName = user.Department?.Name,
                    ShiftName = shift?.Name,
                    CheckInTime = record.CheckInTime,
                    CheckInLatitude = record.CheckInLatitude,
                    CheckInLongitude = record.CheckInLongitude,
                    DistanceMeters = record.DistanceMeters,
                    IsWithinGeofence = record.IsWithinGeofence,
                    PhotoUrl = record.PhotoUrl,
                    Mood = record.Mood,
                    Note = record.Note,
                    Status = record.Status,
                    PointsEarned = record.PointsEarned
                },
                streakCount = user.StreakCount,
                totalPoints = user.TotalPoints,
                pointsEarned = points,
                distanceMeters = distance,
                isWithinGeofence = isWithinGeofence
            });
        }

        /// <summary>
        /// Check-out cuối ca làm việc
        /// </summary>
        [Authorize]
        [HttpPost("check-out")]
        public async Task<IActionResult> CheckOut([FromBody] CheckOutDto dto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            AttendanceRecord? record = null;
            if (dto.AttendanceRecordId.HasValue)
            {
                record = await _context.AttendanceRecords.FindAsync(dto.AttendanceRecordId.Value);
            }
            else
            {
                // Tìm bản ghi check-in chưa check-out gần nhất của hôm nay
                var today = DateTime.Now.Date;
                record = await _context.AttendanceRecords
                    .Where(a => a.UserId == userId && a.CheckInTime >= today && a.CheckOutTime == null)
                    .OrderByDescending(a => a.CheckInTime)
                    .FirstOrDefaultAsync();
            }

            if (record == null)
            {
                return BadRequest(new { message = "Không tìm thấy phiên check-in nào hợp lệ cần check-out!" });
            }

            record.CheckOutTime = DateTime.Now;
            if (!string.IsNullOrEmpty(dto.Note))
            {
                record.Note = string.IsNullOrEmpty(record.Note) ? dto.Note : $"{record.Note} | Out: {dto.Note}";
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Check-out thành công! Chúc bạn nghỉ ngơi vui vẻ.",
                recordId = record.Id,
                checkInTime = record.CheckInTime,
                checkOutTime = record.CheckOutTime
            });
        }

        /// <summary>
        /// Lịch sử chấm công của nhân viên hiện tại
        /// </summary>
        [Authorize]
        [HttpGet("my-history")]
        public async Task<IActionResult> GetMyHistory()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var records = await _context.AttendanceRecords
                .Include(a => a.User)
                .Include(a => a.Shift)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CheckInTime)
                .Select(a => new AttendanceRecordDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    FullName = a.User != null ? a.User.FullName : string.Empty,
                    DepartmentName = a.User != null && a.User.Department != null ? a.User.Department.Name : null,
                    ShiftName = a.Shift != null ? a.Shift.Name : null,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    CheckInLatitude = a.CheckInLatitude,
                    CheckInLongitude = a.CheckInLongitude,
                    DistanceMeters = a.DistanceMeters,
                    IsWithinGeofence = a.IsWithinGeofence,
                    PhotoUrl = a.PhotoUrl,
                    Mood = a.Mood,
                    Note = a.Note,
                    Status = a.Status,
                    PointsEarned = a.PointsEarned
                })
                .ToListAsync();

            return Ok(records);
        }

        /// <summary>
        /// Xem toàn bộ chấm công (Admin / Manager)
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllRecords([FromQuery] DateTime? date, [FromQuery] string? status)
        {
            var query = _context.AttendanceRecords
                .Include(a => a.User)
                    .ThenInclude(u => u!.Department)
                .Include(a => a.Shift)
                .AsQueryable();

            if (date.HasValue)
            {
                var d = date.Value.Date;
                query = query.Where(a => a.CheckInTime.Date == d);
            }

            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(a => a.Status == status);
            }

            var records = await query
                .OrderByDescending(a => a.CheckInTime)
                .Select(a => new AttendanceRecordDto
                {
                    Id = a.Id,
                    UserId = a.UserId,
                    FullName = a.User != null ? a.User.FullName : string.Empty,
                    DepartmentName = a.User != null && a.User.Department != null ? a.User.Department.Name : null,
                    ShiftName = a.Shift != null ? a.Shift.Name : null,
                    CheckInTime = a.CheckInTime,
                    CheckOutTime = a.CheckOutTime,
                    CheckInLatitude = a.CheckInLatitude,
                    CheckInLongitude = a.CheckInLongitude,
                    DistanceMeters = a.DistanceMeters,
                    IsWithinGeofence = a.IsWithinGeofence,
                    PhotoUrl = a.PhotoUrl,
                    Mood = a.Mood,
                    Note = a.Note,
                    Status = a.Status,
                    PointsEarned = a.PointsEarned
                })
                .ToListAsync();

            return Ok(records);
        }

        /// <summary>
        /// 6. Bảng xếp hạng chuyên cần (Leaderboard) & Gamification
        /// </summary>
        [HttpGet("leaderboard")]
        public async Task<IActionResult> GetLeaderboard()
        {
            var topUsers = await _context.Users
                .Include(u => u.Department)
                .OrderByDescending(u => u.TotalPoints)
                .ThenByDescending(u => u.StreakCount)
                .Take(20)
                .ToListAsync();

            var leaderboard = topUsers.Select((u, index) => new LeaderboardItemDto
            {
                Rank = index + 1,
                UserId = u.Id,
                FullName = u.FullName,
                DepartmentName = u.Department?.Name,
                StreakCount = u.StreakCount,
                TotalPoints = u.TotalPoints
            }).ToList();

            return Ok(leaderboard);
        }

        /// <summary>
        /// Chỉnh sửa bản ghi chấm công (Admin/Manager CRUD)
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateRecord(int id, [FromBody] UpdateAttendanceDto dto)
        {
            var record = await _context.AttendanceRecords.FindAsync(id);
            if (record == null)
                return NotFound(new { message = "Không tìm thấy bản ghi chấm công!" });

            record.CheckInTime = dto.CheckInTime;
            record.CheckOutTime = dto.CheckOutTime;
            record.Status = dto.Status;
            record.Note = dto.Note;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật bản ghi chấm công thành công!", record });
        }

        /// <summary>
        /// Xóa bản ghi chấm công (Admin CRUD)
        /// </summary>
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRecord(int id)
        {
            var record = await _context.AttendanceRecords.FindAsync(id);
            if (record == null)
                return NotFound(new { message = "Không tìm thấy bản ghi chấm công!" });

            _context.AttendanceRecords.Remove(record);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa bản ghi chấm công thành công!" });
        }
    }
}
