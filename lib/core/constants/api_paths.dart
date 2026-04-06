/// Mirror of Spring Boot ApiPaths.java
/// Base URL (http://localhost:8081/api/v1) is already in DioClient.
/// These paths are appended after the base URL.
class ApiPaths {
  ApiPaths._();
}

// ─── Authentication ───────────────────────────────────────────────────────

abstract class AuthPaths {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String introspect = '/auth/introspect';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String validateResetToken = '/auth/reset-password/validate';
}

// ─── User ─────────────────────────────────────────────────────────────────

abstract class UserPaths {
  static const String base = '/users';
  static const String me = '/users/me';
  static const String changePassword = '/users/change-password';
  static const String changeAvatar = '/users/change-avatar';
  static const String staff = '/users/staff';
  static String byId(String id) => '/users/$id';
  static String byUsername(String username) => '/users/$username';
  static String lock(String id) => '/users/lock/$id';
  static String unlock(String id) => '/users/unlock/$id';
}

// ─── Movie ────────────────────────────────────────────────────────────────

abstract class MoviePaths {
  static const String base = '/movies';
  static const String nowShowing = '/movies/now-showing';
  static const String comingSoon = '/movies/coming-soon';
  static const String recommend = '/movies/recommend';
  // deprecated alias kept for compatibility
  static const String recommended = '/movies/recommend';
  static const String search = '/movies/search';
  static String byId(String id) => '/movies/$id';
  static String bySlug(String slug) => '/movies/slug/$slug';
  static String updateStatus(String id) => '/movies/$id/status';
  static String searchByKeyword(String keyword) => '/movies/search/$keyword';
  static String images(String movieId) => '/movies/$movieId/images';
  static String imageById(String movieId, String imageId) =>
      '/movies/$movieId/images/$imageId';
  static String people(String movieId) => '/movies/$movieId/people';
  static String personById(String movieId, String peopleId) =>
      '/movies/$movieId/people/$peopleId';
  static String peopleBulkDelete(String movieId) =>
      '/movies/$movieId/people/bulk';
}

// ─── Cinema ───────────────────────────────────────────────────────────────

abstract class CinemaPaths {
  static const String base = '/cinema';
  static String byId(String id) => '/cinema/$id';
  static String toggleStatus(String id) => '/cinema/$id/toggle-status';
  static String roomsByCinema(String cinemaId) => '/cinema/$cinemaId/rooms';
  static String moviesByCinema(String cinemaId) => '/cinema/$cinemaId/movies';
}

// ─── Room ─────────────────────────────────────────────────────────────────

abstract class RoomPaths {
  static const String base = '/rooms';
  static String byId(String id) => '/rooms/$id';
  static String byCinema(String cinemaId) => '/rooms/cinema/$cinemaId';
  static String toggleStatus(String id) => '/rooms/$id/toggle-status';
}

// ─── Seat ─────────────────────────────────────────────────────────────────

abstract class SeatPaths {
  static const String base = '/seats';
  static String byId(String seatId) => '/seats/$seatId';
  static String byRoom(String roomId) => '/seats/rooms/$roomId';
  static String bulkByRoom(String roomId) => '/seats/rooms/$roomId/bulk';
}

// ─── SeatType ─────────────────────────────────────────────────────────────

abstract class SeatTypePaths {
  static const String base = '/seat-types';
  static String byId(String id) => '/seat-types/$id';
}

// ─── Showtime ─────────────────────────────────────────────────────────────

abstract class ShowtimePaths {
  static const String base = '/showtimes';
  static String byId(String id) => '/showtimes/$id';
  static String cancel(String id) => '/showtimes/$id/cancel';
  static String byMovie(String movieId) => '/showtimes/by-movie/$movieId';
  static String byCinema(String cinemaId) => '/showtimes/by-cinema/$cinemaId';
  static String seats(String showtimeId) => '/showtimes/$showtimeId/seats';
  static String lockSeats(String showtimeId) =>
      '/showtimes/$showtimeId/seats/lock';
  static String unlockSeats(String showtimeId) =>
      '/showtimes/$showtimeId/seats/unlock';
  static String myLockedSeats(String showtimeId) =>
      '/showtimes/$showtimeId/seats/my-locked-seats';
}

// ─── Booking ──────────────────────────────────────────────────────────────

abstract class BookingPaths {
  static const String base = '/bookings';
  static const String my = '/bookings/my';
  static String byId(String id) => '/bookings/$id';
  static String cancel(String id) => '/bookings/$id/cancel';
}

// ─── Ticket ───────────────────────────────────────────────────────────────

abstract class TicketPaths {
  static const String base = '/tickets';
  static const String my = '/tickets/my';
  static const String checkIn = '/tickets/check-in';
  static String byBooking(String bookingId) => '/tickets/booking/$bookingId';
  static String qr(String bookingCode) => '/tickets/$bookingCode/qr';
}

// ─── Payment ──────────────────────────────────────────────────────────────

abstract class PaymentPaths {
  static const String base = '/payments';
  static const String vnpayIpn = '/payments/vnpay/ipn';
  static const String vnpayReturn = '/payments/vnpay/return';
  static String byBooking(String bookingId) => '/payments/booking/$bookingId';
  static String refund(String bookingId) =>
      '/payments/booking/$bookingId/refund';
}

// ─── Notification ─────────────────────────────────────────────────────────

abstract class NotificationPaths {
  static const String base = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String markAllRead = '/notifications/mark-all-read';
  static String byId(String id) => '/notifications/$id';
  static String markRead(String id) => '/notifications/$id/read';
}

// ─── Review ───────────────────────────────────────────────────────────────

abstract class ReviewPaths {
  static const String base = '/reviews';
  static String byId(String id) => '/reviews/$id';
  static String byMovie(String movieId) => '/reviews/movies/$movieId';
  static String averageByMovie(String movieId) =>
      '/reviews/movies/$movieId/average-rating';
}

// ─── Category ─────────────────────────────────────────────────────────────

abstract class CategoryPaths {
  static const String base = '/categories';
  static String byId(String id) => '/categories/$id';
}

// ─── People ───────────────────────────────────────────────────────────────

abstract class PeoplePaths {
  static const String base = '/people';
  static String byId(String id) => '/people/$id';
  static String moviesByPeople(String peopleId) => '/people/$peopleId/movies';
}

// ─── Product ──────────────────────────────────────────────────────────────

abstract class ProductPaths {
  static const String base = '/products';
  static const String active = '/products/active';
  static String byId(String id) => '/products/$id';
  static String toggleActive(String id) => '/products/$id/toggle-active';
}

// ─── Combo ────────────────────────────────────────────────────────────────

abstract class ComboPaths {
  static const String base = '/combos';
  static const String active = '/combos/active';
  static String byId(String id) => '/combos/$id';
  static String toggleActive(String comboId) =>
      '/combos/$comboId/toggle-active';
}

// ─── Promotion ────────────────────────────────────────────────────────────

abstract class PromotionPaths {
  static const String base = '/promotions';
  static const String active = '/promotions/active';
  static const String apply = '/promotions/apply';
  static const String preview = '/promotions/preview';
  static String byId(String id) => '/promotions/$id';
  static String byCode(String code) => '/promotions/code/$code';
}

// ─── Dashboard ────────────────────────────────────────────────────────────

abstract class DashboardPaths {
  static const String summary = '/dashboard/summary';
  static const String revenueChart = '/dashboard/revenue-chart';
}

// ─── Statistics ───────────────────────────────────────────────────────────

abstract class StatisticsPaths {
  static const String summary = '/dashboard/statistics/summary';
  static const String revenueChart = '/dashboard/statistics/revenue-chart';
  static const String ticketChart = '/dashboard/statistics/ticket-chart';
  static const String topMovies = '/dashboard/statistics/top-movies';
}

// ─── Cloudinary ───────────────────────────────────────────────────────────

abstract class CloudinaryPaths {
  static const String uploadImage = '/cloudinary/upload/image';
  static const String uploadVideo = '/cloudinary/upload/video';
  static const String delete = '/cloudinary/delete';
}
