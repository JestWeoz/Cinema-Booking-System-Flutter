class UpdateProductRequest {
  final String? name;
  final double? price;
  final String? image;
  final bool? active;

  const UpdateProductRequest({
    this.name,
    this.price,
    this.image,
    this.active,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (price != null) map['price'] = price;
    if (image != null) map['image'] = image;
    if (active != null) map['active'] = active;
    return map;
  }
}
