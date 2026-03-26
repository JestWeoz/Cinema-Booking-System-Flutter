/// Mirror of Spring Boot ApiPaths.java
/// Base URL (http://10.0.2.2:8081/api/v1) is already in DioClient.
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
  static const String me = '/users/me';
  static const String changePassword = '/users/change-password';
  static const String changeAvatar = '/users/change-avatar';
  // Admin-only
  static const String lock = '/users/{id}/lock';
  static const String unlock = '/users/{id}/unlock';
  static String byId(String id) => '/users/$id';
}

abstract class MoviePaths {
  static const String base = '/movies';
  static const String nowShowing = '/movies/now-showing';
  static const String comingSoon = '/movies/coming-soon';
  static const String search = '/movies/search';
  static const String recommended = '/movies/recommended';
  static const String images = '/movies/images';
  static String byId(String id) => '/movies/$id';
  static String imageById(String id) => '/movies/$id/images';
}

abstract class CinemaPaths {
  static const String base = '/cinema';
  static String byId(String id) => '/cinema/$id';
}

abstract class RoomPaths {
  static const String base = '/rooms';
  static String byId(String id) => '/rooms/$id';
  static String byCinema(String cinemaId) => '/rooms?cinemaId=$cinemaId';
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
  static String byId(String id) => '/promotions/$id';
  static String validate(String code) => '/promotions/validate?code=$code';
}

abstract class ShowtimePaths {
  static const String base = '/showtimes';
  static String byId(String id) => '/showtimes/$id';
  static String byMovie(String movieId) => '/showtimes?movieId=$movieId';
  static String byMovieAndDate(String movieId, String date) =>
      '/showtimes?movieId=$movieId&date=$date';
  static String seats(String showtimeId) => '/showtimes/$showtimeId/seats';
}

abstract class BookingPaths {
  static const String base = '/bookings';
  static String byId(String id) => '/bookings/$id';
  static const String my = '/bookings/my';
  static String cancel(String id) => '/bookings/$id/cancel';
}
