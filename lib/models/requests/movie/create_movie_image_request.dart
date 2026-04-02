class CreateMovieImageRequest {
  final List<String> imageUrls;

  const CreateMovieImageRequest({required this.imageUrls});

  Map<String, dynamic> toJson() => {'imageUrls': imageUrls};
}
