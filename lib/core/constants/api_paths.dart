/// Mirror of Spring Boot ApiPaths.java
/// Base URL (http://localhost:8081/api/v1) is already in DioClient.
/// These paths are appended after the base URL.
class ApiPaths {
  ApiPaths._();
}

abstract class AuthPaths {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String introspect = '/auth/introspect';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
}

abstract class UserPaths {
  static const String base = '/users';
  static const String me = '/users/me';
  static const String changePassword = '/users/change-password';
  static const String changeAvatar = '/users/change-avatar';
  static const String staff = '/users/staff';
  static String byId(String id) => '/users/$id';
  static String lock(String id) => '/users/lock/$id';
  static String unlock(String id) => '/users/unlock/$id';
}

abstract class MoviePaths {
  static const String base = '/movies';
  static const String nowShowing = '/movies/now-showing';
  static const String comingSoon = '/movies/coming-soon';
  static const String recommended = '/movies/recommended';
  static const String search = '/movies/search';
  static const String images = '/movies/images';
  static String byId(String id) => '/movies/$id';
  static String updateStatus(String id) => '/movies/$id/status';
  static String searchByKeyword(String keyword) => '/movies/search/$keyword';
  static String imageById(String id) => '/movies/$id/images';
}

abstract class CinemaPaths {
  static const String base = '/cinema';
  static String byId(String id) => '/cinema/$id';
  static String toggleStatus(String id) => '/cinema/$id/toggle-status';
  static String roomsByCinema(String cinemaId) => '/cinema/$cinemaId/rooms';
}

abstract class RoomPaths {
  static const String base = '/rooms';
  static String byId(String id) => '/rooms/$id';
  static String toggleStatus(String id) => '/rooms/$id/toggle-status';
}

abstract class SeatPaths {
  static const String base = '/seats';
  static const String seatType = '/seats/seat_type';
  static String byRoom(String roomId) => '/seats?roomId=$roomId';
  static String byId(String id) => '/seats/$id';
}

abstract class ReviewPaths {
  static const String base = '/reviews';
  static const String averageRating = '/reviews/average-rating';
  static String byMovie(String movieId) => '/reviews?movieId=$movieId';
  static String averageByMovie(String movieId) =>
      '/reviews/average-rating?movieId=$movieId';
}

abstract class CategoryPaths {
  static const String base = '/categories';
  static String byId(String id) => '/categories/$id';
}

abstract class ProductPaths {
  static const String base = '/products';
  static String byId(String id) => '/products/$id';
  static String toggleActive(String id) => '/products/$id/toggle-active';
}

abstract class ComboPaths {
  static const String base = '/combos';
  static String byId(String id) => '/combos/$id';
  static String itemsByCombo(String comboId) => '/combos/$comboId/items';
}

abstract class PeoplePaths {
  static const String base = '/people';
  static String byId(String id) => '/people/$id';
  static String byMovie(String movieId) => '/people?movieId=$movieId';
}

abstract class PromotionPaths {
  static const String base = '/promotions';
  static const String active = '/promotions/active';
  static String byId(String id) => '/promotions/$id';
  static String byCode(String code) => '/promotions/code/$code';
}

abstract class ShowtimePaths {
  static const String base = '/showtimes';
  static String byId(String id) => '/showtimes/$id';
  static String cancel(String id) => '/showtimes/$id/cancel';
  static String byMovie(String movieId) => '/showtimes/by-movie/$movieId';
  static String byCinema(String cinemaId) => '/showtimes/by-cinema/$cinemaId';
  static String seats(String showtimeId) => '/showtimes/$showtimeId/seats';
}

abstract class BookingPaths {
  static const String base = '/bookings';
  static String byId(String id) => '/bookings/$id';
  static const String my = '/bookings/my';
  static String cancel(String id) => '/bookings/$id/cancel';
}

abstract class CloudinaryPaths {
  static const String uploadImage = '/cloudinary/upload-image';
  static const String uploadVideo = '/cloudinary/upload-video';
}
