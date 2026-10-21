# 🏢 SMART ATTENDANCE SYSTEM — HỆ THỐNG CHẤM CÔNG THÔNG MINH

[![.NET](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![C#](https://img.shields.io/badge/C%23-13.0-239120?logo=csharp&logoColor=white)](https://learn.microsoft.com/en-us/dotnet/csharp/)
[![SQL Server](https://img.shields.io/badge/Database-SQL_Server-CC292B?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Đồ án môn học**: Lập Trình Di Động (LTDD)  
> **Sinh viên thực hiện**: Bùi Minh Nhật  
> **Kiến trúc**: 2 Tầng độc lập — BackEnd (ASP.NET Core Web API) & FrontEnd (Flutter Client)

---

## 📖 MỤC LỤC
1. [Giới Thiệu Dự Án](#-giới-thiệu-dự-án)
2. [Tính Năng Nổi Bật & Sáng Tạo](#-tính-năng-nổi-bật--sáng-tạo)
3. [Tài Khoản Thử Nghiệm Có Sẵn](#-tài-khoản-thử-nghiệm-có-sẵn)
4. [Kiến Trúc Hệ Thống & Công Nghệ](#-kiến-trúc-hệ-thống--công-nghệ)
5. [Hướng Dẫn Cài Đặt & Khởi Chạy](#-hướng-dẫn-cài-đặt--khởi-chạy)

---

## 🌟 GIỚI THIỆU DỰ ÁN

**Smart Attendance System** là hệ thống giải pháp chấm công - điểm danh nhân sự thế hệ mới dành cho doanh nghiệp hiện đại. Khắc phục hoàn toàn các nhược điểm của máy chấm công truyền thống hay các ứng dụng dễ bị gian lận vị trí, hệ thống kết hợp sức mạnh của **3 tầng xác thực đồng thời**:
1. **Định vị GPS Geofencing**: Tự động tính cự ly so với bán kính văn phòng bằng công thức Haversine.
2. **Dynamic Anti-Fraud QR Code**: Quét mã QR động tự động làm mới sau mỗi 60 giây chiếu tại sảnh văn phòng.
3. **Chụp ảnh selfie minh chứng**: Camera trước ghi lại hình ảnh nhân viên tại thời điểm chấm công và lưu trữ trên máy chủ.

Ngoài ra, ứng dụng còn tích hợp cơ chế **Gamification (Chuỗi ngày đi làm Streak 🔥 & Điểm chuyên cần ⭐)**, **Bảng xếp hạng (Leaderboard 🏆)** và **Mood Check-in 😊** giúp nâng cao tinh thần làm việc và độ gắn kết của nhân sự.

---

## 🚀 TÍNH NĂNG NỔI BẬT & SÁNG TẠO

| Tính năng | Mô tả chi tiết |
| :--- | :--- |
| **🛡️ Dynamic Anti-Fraud QR** | Mã QR hiển thị trên màn hình Admin tự động đổi mỗi 60s, ngăn chặn triệt để hành vi chụp ảnh gửi bạn bè ở nhà quét hộ! |
| **🔥 Chuỗi Ngày Liên Tục (Streak)** | Giữ vững chuỗi ngày đi làm đúng giờ liên tiếp mỗi ngày (tương tự Duolingo/GitHub). |
| **⭐ Điểm Thưởng & Leaderboard** | Đúng giờ nhận +10 điểm, trễ nhận +5 điểm. Bảng xếp hạng Top 20 vinh danh huy chương 🥇 🥈 🥉. |
| **😊 Mood & Energy Check-in** | Nhân viên chia sẻ mức năng lượng buổi sáng (Năng lượng ⚡, Vui vẻ 😊, Mệt mỏi 😴...) giúp HR nắm bắt sức khỏe tinh thần. |
| **📍 Định Vị GPS Haversine** | Tính cự ly chính xác đến mét giữa người dùng và văn phòng, cảnh báo khi ngoài bán kính cho phép. |
| **🔐 Bảo Mật 2 Lớp (OTP)** | Đăng nhập bằng Mật khẩu + Mã OTP 6 chữ số gửi về email hoặc hiển thị Demo OTP tiện lợi. |
| **👥 Phân Quyền 3 Vai Trò** | Giao diện và quyền hạn chuyên biệt: `Admin` (Quản trị), `Manager` (Quản lý duyệt đơn), `Employee` (Nhân viên). |
| **📋 4 Bộ CRUD Hoàn Chỉnh** | Quản lý Phòng ban, Quản lý Ca làm việc, Đơn xin nghỉ phép, Giám sát và xóa bản ghi chấm công. |

---

## 🔑 TÀI KHOẢN THỬ NGHIỆM CÓ SẴN

Hệ thống đã tự động nạp dữ liệu mẫu (SeedData) vào cơ sở dữ liệu. Màn hình đăng nhập Flutter đã có sẵn **cụm 3 nút bấm 1 chạm** để điền tài khoản tự động:

| Vai trò | Tài khoản | Mật khẩu | Chức năng chính |
| :--- | :--- | :--- | :--- |
| **👑 Admin** | `admin` | `Admin@123` | Chiếu mã Dynamic QR 60s, CRUD Phòng ban (tọa độ GPS), CRUD Ca làm việc, Giám sát chấm công. |
| **💼 Manager (Quản lý)** | `manager` | `Manager@123` | Phê duyệt/từ chối đơn xin nghỉ phép, Giám sát chấm công đội ngũ, Bảng xếp hạng. |
| **👤 Employee (Nhân viên)** | `nhanvien1` | `User@123` | Chấm công 3-trong-1, Check-out tan ca, Làm đơn nghỉ phép, Xem lịch sử cá nhân, Streak 🔥 & Leaderboard. |

> **Lưu ý về OTP**: Khi đăng nhập, hộp thoại xác thực sẽ hiển thị mã **Demo OTP** kèm nút **"Điền mã"** tức thì, giúp kiểm thử mọi chức năng ngay cả khi không có kết nối Internet gửi email.

---

## 🏗️ KIẾN TRÚC HỆ THỐNG & CÔNG NGHỆ

```
                                 [ Flutter Client App ]
                       (Android / iOS / Windows Desktop / Web)
                                          │
                             RESTful API (JSON / FormData)
                             Authorization: Bearer <JWT>
                                          ▼
                         [ ASP.NET Core Web API (.NET 10) ]
                    ├── AuthenticateController (OTP, JWT, Identity)
                    ├── AttendanceController (GPS Haversine, QR, Photo)
                    ├── DepartmentsController & ShiftsController (CRUD)
                    └── LeaveRequestsController (Approval Workflow)
                                          │
                     ┌────────────────────┴────────────────────┐
                     ▼                                         ▼
         [ SQL Server Database ]                   [ wwwroot Static Storage ]
     (Users, Depts, Shifts, Records...)              (Ảnh selfie minh chứng)
```

---

## 🛠️ HƯỚNG DẪN CÀI ĐẶT & KHỞI CHẠY

### 1. Yêu cầu môi trường
- [.NET SDK 10.0](https://dotnet.microsoft.com/download) hoặc .NET 8/9 trở lên.
- [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install).
- SQL Server (LocalDB hoặc SQLEXPRESS).

### 2. Khởi chạy BackEnd
```bash
# 1. Di chuyển vào thư mục backend
cd BuiMinhNhat_BackEnd

# 2. Khởi chạy API Server
dotnet run --launch-profile http
```
- API lắng nghe tại: `http://localhost:5000`
- Swagger UI (OpenAPI): `http://localhost:5000/swagger`
- Database và dữ liệu mẫu tự động được khởi tạo (`Database.MigrateAsync`).

### 3. Khởi chạy FrontEnd
```bash
# 1. Di chuyển vào thư mục frontend
cd BuiMinhNhat_FrontEnd

# 2. Cài đặt các gói phụ thuộc
flutter pub get

# 3. Chạy ứng dụng trên nền tảng mong muốn:
# Chạy trên Windows Desktop:
flutter run -d windows

# Hoặc chạy trên Trình duyệt Web:
flutter run -d chrome

# Hoặc chạy trên Máy ảo Android:
flutter run
```

> **Mẹo cấu hình IP**: Góc trên bên phải màn hình Đăng nhập có biểu tượng ⚙️ (**Cấu hình Server**):
> - **Windows Desktop / Web**: Chọn `http://localhost:5000`
> - **Máy ảo Android**: Chọn `http://10.0.2.2:5000`
> - **Conveyor Cloud**: Nhập link dạng `https://xxxx.conveyor.cloud`
---

## 👨‍💻 TÁC GIẢ
- **Sinh viên**: Bùi Minh Nhật
- **Học phần**: Lập Trình Di Động (LTDD)
- **Đại học Sư phạm TP.HCM (HCMUE)**
