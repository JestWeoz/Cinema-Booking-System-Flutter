class CreateProductRequest {
  final String name;
  final double price;
  final String image;

  const CreateProductRequest({
    required this.name,
    required this.price,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'image': image,
      };
}
