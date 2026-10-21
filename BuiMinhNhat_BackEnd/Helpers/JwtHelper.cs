using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using BuiMinhNhat_BackEnd.Models.Entities;

namespace BuiMinhNhat_BackEnd.Helpers
{
    public class JwtHelper
    {
        private readonly IConfiguration _configuration;

        public JwtHelper(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GenerateToken(ApplicationUser user, IList<string> roles, string? departmentName)
        {
            var jwtSettings = _configuration.GetSection("JWT");
            var secretKey = jwtSettings["Secret"] ?? "SuperSecretKeyForAttendanceAppBuiMinhNhat2026!@#$%^&*()_+";
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id),
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.UserName ?? string.Empty),
                new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
                new Claim("FullName", user.FullName ?? string.Empty),
                new Claim("Initials", user.Initials ?? string.Empty),
                new Claim("DepartmentId", user.DepartmentId?.ToString() ?? string.Empty),
                new Claim("DepartmentName", departmentName ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
                // Cũng thêm claim "role" dạng thường để jwt_decoder ở Flutter dễ đọc
                claims.Add(new Claim("role", role));
            }

            var expiryHours = int.TryParse(jwtSettings["ExpiryHours"], out var hours) ? hours : 72;
            var expires = DateTime.UtcNow.AddHours(expiryHours);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = expires,
                Issuer = jwtSettings["ValidIssuer"],
                Audience = jwtSettings["ValidAudience"],
                SigningCredentials = credentials
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
