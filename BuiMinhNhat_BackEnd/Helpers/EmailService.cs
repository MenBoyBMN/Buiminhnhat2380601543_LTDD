using System.Net;
using System.Net.Mail;

namespace BuiMinhNhat_BackEnd.Helpers
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode)
        {
            var emailSettings = _configuration.GetSection("EmailSettings");
            bool enableRealEmail = emailSettings.GetValue<bool>("EnableRealEmail");

            _logger.LogInformation("==================================================");
            _logger.LogInformation(">>> MÃ OTP ĐĂNG NHẬP CHO [{toEmail}] ({fullName}): [{otpCode}] (Hạn 5 phút)", toEmail, fullName, otpCode);
            _logger.LogInformation("==================================================");

            if (!enableRealEmail)
            {
                // Giả lập gửi email thành công
                return true;
            }

            try
            {
                var smtpServer = emailSettings["SmtpServer"] ?? "smtp.gmail.com";
                var smtpPort = emailSettings.GetValue<int>("SmtpPort", 587);
                var senderEmail = emailSettings["SenderEmail"] ?? "";
                var senderPassword = emailSettings["SenderPassword"] ?? "";
                var senderName = emailSettings["SenderName"] ?? "Hệ Thống Chấm Công Thông Minh";

                using var client = new SmtpClient(smtpServer, smtpPort)
                {
                    Credentials = new NetworkCredential(senderEmail, senderPassword),
                    EnableSsl = true
                };

                var mailMessage = new MailMessage
                {
                    From = new MailAddress(senderEmail, senderName),
                    Subject = "Mã xác thực đăng nhập (OTP) - Smart Attendance",
                    Body = $@"
                        <div style='font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;'>
                            <h2 style='color: #1976D2;'>Mã Xác Thực OTP</h2>
                            <p>Xin chào <strong>{fullName}</strong>,</p>
                            <p>Mã OTP để đăng nhập vào hệ thống chấm công của bạn là:</p>
                            <div style='font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #D32F2F; margin: 15px 0;'>{otpCode}</div>
                            <p>Mã này có hiệu lực trong vòng <strong>5 phút</strong>. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                            <hr style='border: none; border-top: 1px solid #eee;' />
                            <p style='color: #888; font-size: 12px;'>Hệ thống Chấm Công Nhân Viên Thông Minh</p>
                        </div>
                    ",
                    IsBodyHtml = true
                };
                mailMessage.To.Add(toEmail);

                await client.SendMailAsync(mailMessage);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Không thể gửi email qua SMTP: {Message}. Vẫn sử dụng mã OTP mô phỏng trên console/response.", ex.Message);
                return false;
            }
        }
    }
}
