=================================
BuiMinhNhat_BackEnd - Folder Guide
=================================

Cách Cấu Hình: 
[ReName]
1.Đổi tên từ folder tổng dự án,folder source code,và file .slnx
2.Khi vào bạn sẻ thấy notfound file, bạn vào Solution {Dự án Của Bạn} -> Add -> Existing Project -> Tìm và Chọn file .csproj trong folder source code của bạn.
3.Chạy Thử coi đc hem

Controllers/
- Chứa các API Controller.
- Nhận Request từ Client, gọi Service/Repository xử lý và trả Response.

Models/
- Chứa các model của ứng dụng.
- Entities/: Các class ánh xạ với bảng trong Database.
- DTOs/: Đối tượng dùng để trao đổi dữ liệu giữa Client và API.
- ViewModels/: Dữ liệu phục vụ hiển thị hoặc trả về theo nhu cầu riêng.

Data/
- Quản lý truy cập dữ liệu.
- MyDbContext: Kết nối và quản lý Entity Framework Core.
- SeedData: Dữ liệu mẫu khởi tạo Database.
- Configurations: Cấu hình Entity (Fluent API, quan hệ, khóa,...).

Repositories/
- Lớp làm việc trực tiếp với Database.
- Interfaces/: Định nghĩa các phương thức thao tác dữ liệu.
- Implementations/: Cài đặt các phương thức đã định nghĩa.

Services/
- Chứa nghiệp vụ (Business Logic) của hệ thống.
- Interfaces/: Khai báo các Service.
- Implementations/: Xử lý nghiệp vụ.

Mapping/
- Cấu hình AutoMapper.
- Chuyển đổi giữa Entity, DTO và ViewModel.

Helpers/
- Chứa các lớp hỗ trợ dùng chung.
- Ví dụ: JWT, Hash Password, Upload File, Utility,...

Middleware/
- Xử lý Request/Response trước hoặc sau Controller.
- Ví dụ: Exception Handling, Logging, Authentication,...

Migrations/
- Chứa lịch sử Migration của Entity Framework Core.
- Dùng để tạo và cập nhật Database.

appsettings.json
- Chứa cấu hình ứng dụng.
- Ví dụ: Connection String, JWT Secret, Logging,...

Program.cs
- Điểm khởi động của ứng dụng.
- Đăng ký Services, Middleware và cấu hình HTTP Pipeline.