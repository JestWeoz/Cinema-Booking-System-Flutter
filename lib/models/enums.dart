// ignore_for_file: constant_identifier_names

// Tat ca enum khop voi backend Spring Boot

enum Gender { MALE, FEMALE, OTHER }

enum MovieStatus { COMING_SOON, NOW_SHOWING, ENDED }

enum MovieRole { ACTOR, DIRECTOR, PRODUCER, WRITER }

enum AgeRating { P, C13, C16, C18 }

enum Language { ORIGINAL, DUBBED, SUBTITLED }

enum ShowTimeStatus { SCHEDULED, ONGOING, FINISHED, CANCELLED }

enum RoomType { TWO_D, THREE_D, FOUR_D, IMAX, SWEETBOX }

enum SeatTypeEnum { STANDARD, VIP, COUPLE }

enum SeatStatus { AVAILABLE, LOCKED, BOOKED }

enum BookingStatus { PENDING, CONFIRMED, CANCELLED, EXPIRED, REFUNDED }

enum TicketStatus { VALID, USED, CANCELLED, PENDING_PAYMENT, EXPIRED }

enum ItemType { PRODUCT, COMBO }

enum PaymentMethod { VNPAY, MOMO, ZALOPAY, CASH, CREDIT_CARD }

enum PaymentStatus { PENDING, SUCCESS, FAILED, REFUNDED }

enum DiscountType { PERCENTAGE, FIXED }

enum Status { ACTIVE, INACTIVE }

enum NotificationType {
  BOOKING,
  PAYMENT,
  REMINDER,
  PROMOTION,
  SYSTEM,
  CANCELLATION,
  REVIEW
}

RoomType? roomTypeFromJson(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'TWO_D':
    case '2D':
    case 'STANDARD':
      return RoomType.TWO_D;
    case 'THREE_D':
    case '3D':
      return RoomType.THREE_D;
    case 'FOUR_D':
    case '4D':
    case 'FOUR_DX':
    case '4DX':
      return RoomType.FOUR_D;
    case 'IMAX':
      return RoomType.IMAX;
    case 'SWEETBOX':
    case 'VIP':
      return RoomType.SWEETBOX;
    default:
      return null;
  }
}

String roomTypeToApi(RoomType type) {
  switch (type) {
    case RoomType.TWO_D:
      return 'TWO_D';
    case RoomType.THREE_D:
      return 'THREE_D';
    case RoomType.FOUR_D:
      return 'FOUR_D';
    case RoomType.IMAX:
      return 'IMAX';
    case RoomType.SWEETBOX:
      return 'SWEETBOX';
  }
}

String roomTypeLabel(RoomType? type) {
  switch (type) {
    case RoomType.TWO_D:
      return '2D';
    case RoomType.THREE_D:
      return '3D';
    case RoomType.FOUR_D:
      return '4D';
    case RoomType.IMAX:
      return 'IMAX';
    case RoomType.SWEETBOX:
      return 'Sweetbox';
    default:
      return 'N/A';
  }
}

Language? languageFromJson(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'ORIGINAL':
    case 'ENGLISH':
      return Language.ORIGINAL;
    case 'DUBBED':
    case 'VIETNAMESE':
      return Language.DUBBED;
    case 'SUBTITLED':
      return Language.SUBTITLED;
    default:
      return null;
  }
}

String languageLabel(Language? language) {
  switch (language) {
    case Language.ORIGINAL:
      return 'Original';
    case Language.DUBBED:
      return 'Dubbed';
    case Language.SUBTITLED:
      return 'Subtitled';
    default:
      return 'N/A';
  }
}

ShowTimeStatus? showTimeStatusFromJson(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'SCHEDULED':
    case 'UPCOMING':
      return ShowTimeStatus.SCHEDULED;
    case 'ONGOING':
      return ShowTimeStatus.ONGOING;
    case 'FINISHED':
      return ShowTimeStatus.FINISHED;
    case 'CANCELLED':
      return ShowTimeStatus.CANCELLED;
    default:
      return null;
  }
}

String showTimeStatusToApi(ShowTimeStatus status) {
  switch (status) {
    case ShowTimeStatus.SCHEDULED:
      return 'SCHEDULED';
    case ShowTimeStatus.ONGOING:
      return 'ONGOING';
    case ShowTimeStatus.FINISHED:
      return 'FINISHED';
    case ShowTimeStatus.CANCELLED:
      return 'CANCELLED';
  }
}

String showTimeStatusLabel(ShowTimeStatus? status) {
  switch (status) {
    case ShowTimeStatus.SCHEDULED:
      return 'Scheduled';
    case ShowTimeStatus.ONGOING:
      return 'Ongoing';
    case ShowTimeStatus.FINISHED:
      return 'Finished';
    case ShowTimeStatus.CANCELLED:
      return 'Cancelled';
    default:
      return 'N/A';
  }
}
