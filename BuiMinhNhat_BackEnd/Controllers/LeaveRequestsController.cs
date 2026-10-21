using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using BuiMinhNhat_BackEnd.Data;
using BuiMinhNhat_BackEnd.Models.DTOs;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class LeaveRequestsController : ControllerBase
    {
        private readonly MyDbContext _context;

        public LeaveRequestsController(MyDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Danh sách đơn nghỉ phép của nhân viên hiện tại
        /// </summary>
        [Authorize]
        [HttpGet("my-requests")]
        public async Task<IActionResult> GetMyRequests()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var list = await _context.LeaveRequests
                .Include(l => l.User)
                .Where(l => l.UserId == userId)
                .OrderByDescending(l => l.CreatedAt)
                .Select(l => new LeaveRequestDto
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    FullName = l.User != null ? l.User.FullName : "",
                    DepartmentName = l.User != null && l.User.Department != null ? l.User.Department.Name : null,
                    LeaveType = l.LeaveType,
                    StartDate = l.StartDate,
                    EndDate = l.EndDate,
                    Reason = l.Reason,
                    Status = l.Status,
                    ReviewedBy = l.ReviewedByUserId,
                    ReviewNote = l.ReviewNote,
                    CreatedAt = l.CreatedAt,
                    ReviewedAt = l.ReviewedAt
                })
                .ToListAsync();

            return Ok(list);
        }

        /// <summary>
        /// Tạo đơn xin nghỉ phép mới (CRUD Employee)
        /// </summary>
        [Authorize]
        [HttpPost]
        public async Task<IActionResult> CreateRequest([FromBody] CreateLeaveRequestDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            var request = new LeaveRequest
            {
                UserId = userId,
                LeaveType = dto.LeaveType,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate,
                Reason = dto.Reason,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _context.LeaveRequests.Add(request);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gửi đơn xin nghỉ phép thành công! Đang chờ quản lý phê duyệt.", id = request.Id });
        }

        /// <summary>
        /// Sửa đơn xin nghỉ phép khi còn đang ở trạng thái 'Pending' (CRUD Employee)
        /// </summary>
        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateRequest(int id, [FromBody] CreateLeaveRequestDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var request = await _context.LeaveRequests.FindAsync(id);

            if (request == null)
                return NotFound(new { message = "Không tìm thấy đơn xin nghỉ phép!" });

            if (request.UserId != userId && !User.IsInRole("Admin"))
                return Forbid();

            if (request.Status != "Pending")
                return BadRequest(new { message = "Đơn nghỉ phép này đã được xử lý, không thể chỉnh sửa!" });

            request.LeaveType = dto.LeaveType;
            request.StartDate = dto.StartDate;
            request.EndDate = dto.EndDate;
            request.Reason = dto.Reason;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật đơn xin nghỉ phép thành công!", request });
        }

        /// <summary>
        /// Xóa đơn xin nghỉ phép khi còn 'Pending' (CRUD Employee)
        /// </summary>
        [Authorize]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRequest(int id)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var request = await _context.LeaveRequests.FindAsync(id);

            if (request == null)
                return NotFound(new { message = "Không tìm thấy đơn xin nghỉ phép!" });

            if (request.UserId != userId && !User.IsInRole("Admin"))
                return Forbid();

            if (request.Status != "Pending" && !User.IsInRole("Admin"))
                return BadRequest(new { message = "Đơn đã được duyệt hoặc từ chối, không thể xóa!" });

            _context.LeaveRequests.Remove(request);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa đơn xin nghỉ phép!" });
        }

        /// <summary>
        /// Lấy toàn bộ danh sách đơn nghỉ phép (Dành cho Manager/Admin)
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllRequests([FromQuery] string? status)
        {
            var query = _context.LeaveRequests
                .Include(l => l.User)
                    .ThenInclude(u => u!.Department)
                .AsQueryable();

            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(l => l.Status == status);
            }

            var list = await query
                .OrderByDescending(l => l.CreatedAt)
                .Select(l => new LeaveRequestDto
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    FullName = l.User != null ? l.User.FullName : "",
                    DepartmentName = l.User != null && l.User.Department != null ? l.User.Department.Name : null,
                    LeaveType = l.LeaveType,
                    StartDate = l.StartDate,
                    EndDate = l.EndDate,
                    Reason = l.Reason,
                    Status = l.Status,
                    ReviewedBy = l.ReviewedByUserId,
                    ReviewNote = l.ReviewNote,
                    CreatedAt = l.CreatedAt,
                    ReviewedAt = l.ReviewedAt
                })
                .ToListAsync();

            return Ok(list);
        }

        /// <summary>
        /// Phê duyệt hoặc Từ chối đơn nghỉ phép (Manager / Admin)
        /// </summary>
        [Authorize(Roles = "Admin,Manager")]
        [HttpPost("{id}/review")]
        public async Task<IActionResult> ReviewRequest(int id, [FromBody] ReviewLeaveRequestDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var reviewerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var reviewerName = User.FindFirstValue("FullName") ?? User.Identity?.Name;

            var request = await _context.LeaveRequests.FindAsync(id);
            if (request == null)
                return NotFound(new { message = "Không tìm thấy đơn xin nghỉ phép!" });

            request.Status = dto.Status; // "Approved" or "Rejected"
            request.ReviewedByUserId = reviewerName ?? reviewerId;
            request.ReviewNote = dto.ReviewNote;
            request.ReviewedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = dto.Status == "Approved" ? "Đã duyệt đơn nghỉ phép!" : "Đã từ chối đơn nghỉ phép!",
                id = request.Id,
                status = request.Status
            });
        }
    }
}
