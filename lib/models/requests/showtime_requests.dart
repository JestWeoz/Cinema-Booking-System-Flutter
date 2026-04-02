// Showtime Requests — khớp với backend DTO/Request/Showtime/
import '../enums.dart';

class ShowtimeFilterRequest {
  final String? movieId;
  final String? cinemaId;
  final String? roomId;
  final String? date; // ISO date: "yyyy-MM-dd"
  final Language? language;
  final ShowTimeStatus? status;
  final String? keyword;
  final int page;
  final int size;

  const ShowtimeFilterRequest({
    this.movieId,
    this.cinemaId,
    this.roomId,
    this.date,
    this.language,
    this.status,
    this.keyword,
    this.page = 0,
    this.size = 20,
  });

  Map<String, dynamic> toQueryParams() => {
        if (movieId != null) 'movieId': movieId,
        if (cinemaId != null) 'cinemaId': cinemaId,
        if (roomId != null) 'roomId': roomId,
        if (date != null) 'date': date,
        if (language != null) 'language': language!.name,
        if (status != null) 'status': status!.name,
        if (keyword != null) 'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      };
}

class CreateShowtimeRequest {
  final String movieId;
  final String roomId;
  final String startTime; // ISO datetime
  final double basePrice;
  final String language;

  const CreateShowtimeRequest({
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.basePrice,
    required this.language,
  });

  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'roomId': roomId,
        'startTime': startTime,
        'basePrice': basePrice,
        'language': language,
      };
}

class UpdateShowtimeRequest {
  final String? startTime;
  final double? basePrice;
  final String? language;

  const UpdateShowtimeRequest({this.startTime, this.basePrice, this.language});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (startTime != null) map['startTime'] = startTime;
    if (basePrice != null) map['basePrice'] = basePrice;
    if (language != null) map['language'] = language;
    return map;
  }
}
