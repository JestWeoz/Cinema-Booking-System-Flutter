# 🎬 Cinema Booking System — Flutter App

Mobile app đặt vé xem phim, kết nối với backend **Spring Boot** (port `8081`).

---

## ⚙️ Yêu cầu hệ thống

| Tool | Phiên bản |
|---|---|
| Flutter | ≥ 3.5.0 |
| Dart | ≥ 3.5.0 |
| Android Studio / VS Code | Mới nhất |
| Spring Boot Backend | Chạy trên port `8081` |

---

## 🚀 Hướng dẫn chạy sau khi pull

### 1. Clone repo

```bash
git clone https://github.com/JestWeoz/Cinema-Booking-System-Flutter.git
cd Cinema-Booking-System-Flutter
```

### 2. Cài dependencies

```bash
flutter pub get
```

### 3. Cấu hình Backend URL

Mở file [`lib/core/constants/app_constants.dart`](lib/core/constants/app_constants.dart) và đổi `baseUrl` cho phù hợp:

```dart
// Android Emulator (trỏ về localhost của máy)
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';

// Thiết bị thật (thay bằng IP máy tính trong cùng mạng LAN)
static const String baseUrl = 'http://192.168.x.x:8081/api/v1';

// Web / Chrome
static const String baseUrl = 'http://localhost:8081/api/v1';
```

> 💡 Xem IP máy: `ipconfig` (Windows) hoặc `ifconfig` (macOS/Linux)

### 4. Khởi động Spring Boot backend

Đảm bảo backend đang chạy trên port `8081` trước khi mở app.

### 5. Chạy app

```bash
# Android emulator
flutter run -d android

# Thiết bị thật
flutter run -d <device-id>

# Chrome (cần bật CORS trên Spring Boot)
flutter run -d chrome
```

---

## 🏗️ Cấu trúc dự án

```
lib/
├── main.dart                  # Entry point
├── app/
│   ├── di/service_locator.dart  # Dependency Injection (GetIt)
│   ├── router/app_router.dart   # Navigation (go_router)
│   └── shell/main_shell.dart    # Bottom Navigation Bar
├── core/
│   ├── constants/             # API paths, routes, storage keys
│   ├── theme/                 # Colors, typography, ThemeData
│   ├── errors/                # Typed Failures
│   ├── network/               # Dio client + interceptors
│   ├── extensions/            # BuildContext, String helpers
│   └── utils/                 # DateTime, Currency formatters
├── shared/widgets/            # AppButton, AppTextField, AppShimmer...
└── features/
    ├── auth/                  # Đăng nhập / Đăng ký
    ├── home/                  # Trang chủ
    ├── movies/                # Danh sách & chi tiết phim
    ├── booking/               # Chọn ghế & đặt vé
    ├── ticket/                # Vé của tôi
    └── profile/               # Hồ sơ cá nhân
```

---

## 🧱 Tech Stack

| Layer | Package |
|---|---|
| State Management | `flutter_bloc` |
| Navigation | `go_router` |
| Dependency Injection | `get_it` |
| HTTP Client | `dio` (kết nối Spring Boot) |
| Secure Storage | `flutter_secure_storage` |
| Error Handling | `dartz` (Either) |
| Images | `cached_network_image` |

---

## 🌐 API Endpoints (Spring Boot)

Base URL: `http://<host>:8081/api/v1`

| Feature | Endpoint |
|---|---|
| Auth | `/auth/login`, `/auth/register`, `/auth/refresh` |
| Movies | `/movies/now-showing`, `/movies/coming-soon`, `/movies/search` |
| Booking | `/bookings`, `/bookings/my` |
| User | `/users/me`, `/users/change-password` |
| Showtime | `/showtimes` |
| Cinema | `/cinema` |

---

## 🔑 Lưu ý bảo mật

- Token JWT được lưu trong `flutter_secure_storage` (mã hóa)
- Auto refresh token khi hết hạn (401 handler trong `auth_interceptor.dart`)
- Không commit file `.env` hoặc `google-services.json`
