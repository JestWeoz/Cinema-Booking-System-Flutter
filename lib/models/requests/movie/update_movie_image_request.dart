class UpdateMovieImageRequest {
  final List<String> imageUrls;

  const UpdateMovieImageRequest({required this.imageUrls});

  Map<String, dynamic> toJson() => {'imageUrls': imageUrls};
}
