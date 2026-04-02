// Promotion, Product, Combo, Cinema, Notification Responses
import '../enums.dart';

// ─── Promotion ────────────────────────────────────────────────────────────

class PromotionResponse {
  final String id;
  final String code;
  final String name;
  final String? description;
  final DiscountType? discountType;
  final double discountValue;
  final double? minOrderValue;
  final double? maxDiscount;
  final int? quantity;
  final int? usedQuantity;
  final String? startDate; // ISO date
  final String? endDate;
  final int? maxUsagePerUser;
  final bool active;

  const PromotionResponse({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.maxDiscount,
    this.quantity,
    this.usedQuantity,
    this.startDate,
    this.endDate,
    this.maxUsagePerUser,
    required this.active,
  });

  factory PromotionResponse.fromJson(Map<String, dynamic> json) =>
      PromotionResponse(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        discountType: json['discountType'] != null
            ? DiscountType.values.byName(json['discountType'])
            : null,
        discountValue: (json['discountValue'] ?? 0).toDouble(),
        minOrderValue: json['minOrderValue']?.toDouble(),
        maxDiscount: json['maxDiscount']?.toDouble(),
        quantity: json['quantity'],
        usedQuantity: json['usedQuantity'],
        startDate: json['startDate'],
        endDate: json['endDate'],
        maxUsagePerUser: json['maxUsagePerUser'],
        active: json['active'] ?? false,
      );
}

// ─── Product ──────────────────────────────────────────────────────────────

class ProductResponse {
  final String id;
  final String name;
  final double price;
  final String? image;
  final bool? active;

  const ProductResponse({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.active,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) =>
      ProductResponse(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        image: json['image'],
        active: json['active'],
      );
}

// ─── Combo ────────────────────────────────────────────────────────────────

class ComboItemResponse {
  final String productId;
  final String productName;
  final int quantity;

  const ComboItemResponse({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  factory ComboItemResponse.fromJson(Map<String, dynamic> json) =>
      ComboItemResponse(
        productId: json['productId'] ?? '',
        productName: json['productName'] ?? '',
        quantity: json['quantity'] ?? 0,
      );
}

class ComboResponse {
  final String id;
  final String name;
  final double price;
  final String? image;
  final String? description;
  final bool active;
  final List<ComboItemResponse> items;

  const ComboResponse({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
    required this.active,
    required this.items,
  });

  factory ComboResponse.fromJson(Map<String, dynamic> json) => ComboResponse(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        image: json['image'],
        description: json['description'],
        active: json['active'] ?? false,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ComboItemResponse.fromJson(e))
                .toList() ??
            [],
      );
}

// ─── Cinema ───────────────────────────────────────────────────────────────

class CinemaResponse {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? hotline;
  final String? logoUrl;
  final Status? status;

  const CinemaResponse({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.hotline,
    this.logoUrl,
    this.status,
  });

  factory CinemaResponse.fromJson(Map<String, dynamic> json) => CinemaResponse(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        phone: json['phone'],
        hotline: json['hotline'],
        logoUrl: json['logoUrl'],
        status:
            json['status'] != null ? Status.values.byName(json['status']) : null,
      );
}

// ─── Notification ─────────────────────────────────────────────────────────

class NotificationResponse {
  final String notificationId;
  final String title;
  final String body;
  final NotificationType? type;
  final bool read;
  final String? createdAt;

  const NotificationResponse({
    required this.notificationId,
    required this.title,
    required this.body,
    this.type,
    required this.read,
    this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      NotificationResponse(
        notificationId: json['notificationId'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] != null
            ? NotificationType.values.byName(json['type'])
            : null,
        read: json['read'] ?? false,
        createdAt: json['createdAt'],
      );
}
