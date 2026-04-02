// Tất cả enum khớp với backend Spring Boot

enum Gender { MALE, FEMALE, OTHER }

enum MovieStatus { COMING_SOON, NOW_SHOWING, ENDED }

enum MovieRole { DIRECTOR, ACTOR, PRODUCER, WRITER, COMPOSER }

enum AgeRating { G, PG, PG13, T16, T18, C }

enum Language { VIETNAMESE, ENGLISH, SUBTITLED, DUBBED }

enum ShowTimeStatus { UPCOMING, ONGOING, FINISHED, CANCELLED }

enum RoomType { STANDARD, IMAX, FOUR_DX, THREE_D, VIP }

enum SeatTypeEnum { STANDARD, VIP, SWEETBOX, COUPLE }

enum SeatStatus { AVAILABLE, LOCKED, BOOKED }

enum BookingStatus { PENDING, CONFIRMED, CANCELLED, EXPIRED }

enum TicketStatus { ACTIVE, USED, CANCELLED }

enum ItemType { PRODUCT, COMBO }

enum PaymentMethod { VNPAY, MOMO, CASH }

enum PaymentStatus { PENDING, SUCCESS, FAILED, REFUNDED }

enum DiscountType { PERCENT, FIXED }

enum Status { ACTIVE, INACTIVE }

enum NotificationType { BOOKING, PAYMENT, SYSTEM, PROMOTION }
