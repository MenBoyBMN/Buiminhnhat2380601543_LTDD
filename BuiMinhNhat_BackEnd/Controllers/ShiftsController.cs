using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using BuiMinhNhat_BackEnd.Data;
using BuiMinhNhat_BackEnd.Models.DTOs;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ShiftsController : ControllerBase
    {
        private readonly MyDbContext _context;

        public ShiftsController(MyDbContext context)
        {
            _context = context;
        }

        // GET: api/Shifts
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var shifts = await _context.Shifts
                .Select(s => new ShiftDto
                {
                    Id = s.Id,
                    Name = s.Name,
                    StartTime = s.StartTime.ToString(@"hh\:mm"),
                    EndTime = s.EndTime.ToString(@"hh\:mm"),
                    GracePeriodMinutes = s.GracePeriodMinutes,
                    IsActive = s.IsActive
                })
                .ToListAsync();

            return Ok(shifts);
        }

        // GET: api/Shifts/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var shift = await _context.Shifts.FindAsync(id);
            if (shift == null)
                return NotFound(new { message = "Không tìm thấy ca làm việc!" });

            return Ok(new ShiftDto
            {
                Id = shift.Id,
                Name = shift.Name,
                StartTime = shift.StartTime.ToString(@"hh\:mm"),
                EndTime = shift.EndTime.ToString(@"hh\:mm"),
                GracePeriodMinutes = shift.GracePeriodMinutes,
                IsActive = shift.IsActive
            });
        }

        // POST: api/Shifts (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateUpdateShiftDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (!TimeSpan.TryParse(dto.StartTime, out var startTime) || !TimeSpan.TryParse(dto.EndTime, out var endTime))
            {
                return BadRequest(new { message = "Thời gian không đúng định dạng HH:mm (Ví dụ: 08:00)!" });
            }

            var shift = new Shift
            {
                Name = dto.Name,
                StartTime = startTime,
                EndTime = endTime,
                GracePeriodMinutes = dto.GracePeriodMinutes,
                IsActive = dto.IsActive
            };

            _context.Shifts.Add(shift);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = shift.Id }, new ShiftDto
            {
                Id = shift.Id,
                Name = shift.Name,
                StartTime = shift.StartTime.ToString(@"hh\:mm"),
                EndTime = shift.EndTime.ToString(@"hh\:mm"),
                GracePeriodMinutes = shift.GracePeriodMinutes,
                IsActive = shift.IsActive
            });
        }

        // PUT: api/Shifts/5 (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] CreateUpdateShiftDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var shift = await _context.Shifts.FindAsync(id);
            if (shift == null)
                return NotFound(new { message = "Không tìm thấy ca làm việc!" });

            if (!TimeSpan.TryParse(dto.StartTime, out var startTime) || !TimeSpan.TryParse(dto.EndTime, out var endTime))
            {
                return BadRequest(new { message = "Thời gian không đúng định dạng HH:mm!" });
            }

            shift.Name = dto.Name;
            shift.StartTime = startTime;
            shift.EndTime = endTime;
            shift.GracePeriodMinutes = dto.GracePeriodMinutes;
            shift.IsActive = dto.IsActive;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật ca làm việc thành công!", shift });
        }

        // DELETE: api/Shifts/5 (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var shift = await _context.Shifts.FindAsync(id);
            if (shift == null)
                return NotFound(new { message = "Không tìm thấy ca làm việc!" });

            _context.Shifts.Remove(shift);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa ca làm việc thành công!" });
        }
    }
}
