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
    public class DepartmentsController : ControllerBase
    {
        private readonly MyDbContext _context;

        public DepartmentsController(MyDbContext context)
        {
            _context = context;
        }

        // GET: api/Departments
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var depts = await _context.Departments
                .Include(d => d.Users)
                .Select(d => new DepartmentDto
                {
                    Id = d.Id,
                    Name = d.Name,
                    Description = d.Description,
                    OfficeAddress = d.OfficeAddress,
                    Latitude = d.Latitude,
                    Longitude = d.Longitude,
                    RadiusMeters = d.RadiusMeters,
                    UserCount = d.Users.Count
                })
                .ToListAsync();

            return Ok(depts);
        }

        // GET: api/Departments/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var dept = await _context.Departments
                .Include(d => d.Users)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (dept == null)
                return NotFound(new { message = "Không tìm thấy phòng ban!" });

            return Ok(new DepartmentDto
            {
                Id = dept.Id,
                Name = dept.Name,
                Description = dept.Description,
                OfficeAddress = dept.OfficeAddress,
                Latitude = dept.Latitude,
                Longitude = dept.Longitude,
                RadiusMeters = dept.RadiusMeters,
                UserCount = dept.Users.Count
            });
        }

        // POST: api/Departments (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateUpdateDepartmentDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var dept = new Department
            {
                Name = dto.Name,
                Description = dto.Description,
                OfficeAddress = dto.OfficeAddress,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                RadiusMeters = dto.RadiusMeters
            };

            _context.Departments.Add(dept);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = dept.Id }, new DepartmentDto
            {
                Id = dept.Id,
                Name = dept.Name,
                Description = dept.Description,
                OfficeAddress = dept.OfficeAddress,
                Latitude = dept.Latitude,
                Longitude = dept.Longitude,
                RadiusMeters = dept.RadiusMeters,
                UserCount = 0
            });
        }

        // PUT: api/Departments/5 (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] CreateUpdateDepartmentDto dto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var dept = await _context.Departments.FindAsync(id);
            if (dept == null)
                return NotFound(new { message = "Không tìm thấy phòng ban!" });

            dept.Name = dto.Name;
            dept.Description = dto.Description;
            dept.OfficeAddress = dto.OfficeAddress;
            dept.Latitude = dto.Latitude;
            dept.Longitude = dto.Longitude;
            dept.RadiusMeters = dto.RadiusMeters;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Cập nhật thông tin phòng ban thành công!", department = dept });
        }

        // DELETE: api/Departments/5 (CRUD Admin)
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var dept = await _context.Departments.Include(d => d.Users).FirstOrDefaultAsync(d => d.Id == id);
            if (dept == null)
                return NotFound(new { message = "Không tìm thấy phòng ban!" });

            if (dept.Users.Any())
            {
                return BadRequest(new { message = "Không thể xóa phòng ban đang có nhân viên! Vui lòng chuyển nhân viên sang phòng ban khác trước." });
            }

            _context.Departments.Remove(dept);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa phòng ban thành công!" });
        }
    }
}
