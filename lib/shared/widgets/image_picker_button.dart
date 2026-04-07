import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';
import 'package:cinema_booking_system_app/shared/widgets/app_network_image.dart';

/// Widget chọn & upload ảnh với preview tức thì — dùng cho avatar, poster…
///
/// Preview hiện **ngay** từ bytes local khi vừa chọn file,
/// upload Cloudinary chạy ngầm sau.
enum ImagePickerButtonShape { circle, rectangle, square }

class ImagePickerButton extends StatefulWidget {
  final String? currentImageUrl;
  final String label;
  final double size;
  final ImagePickerButtonShape shape;
  final void Function(String url) onUploaded;
  final void Function(String error)? onError;

  const ImagePickerButton({
    super.key,
    required this.label,
    required this.onUploaded,
    this.currentImageUrl,
    this.size = 120,
    this.shape = ImagePickerButtonShape.rectangle,
    this.onError,
  });

  @override
  State<ImagePickerButton> createState() => _ImagePickerButtonState();
}

class _ImagePickerButtonState extends State<ImagePickerButton> {
  bool _uploading = false;

  /// Bytes của ảnh đã chọn → hiện preview ngay lập tức
  Uint8List? _localBytes;

  /// URL trả về sau khi upload Cloudinary thành công
  String? _uploadedUrl;

  // ─── Pick & Upload ────────────────────────────────────────────────────────

  Future<void> _pick(BuildContext sheetCtx, ImageSource source) async {
    // Đóng đúng sheet nguồn ảnh — không đóng form cha
    Navigator.of(sheetCtx).pop();

    // 1. Chọn file
    final XFile? picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    // 2. Đọc bytes → hiện preview ngay (Image.memory)
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _localBytes = bytes);

    // 3. Upload lên Cloudinary ngầm
    setState(() => _uploading = true);
    try {
      final url = await MediaUploadHelper.uploadImageBytes(
        bytes,
        filename: picked.name,
      );
      if (url != null && mounted) {
        setState(() => _uploadedUrl = url);
        widget.onUploaded(url);
      } else if (mounted) {
        _showError('Tải ảnh lên thất bại, vui lòng thử lại');
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(String msg) {
    if (widget.onError != null) {
      widget.onError!(msg);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh lên: $msg'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─── Source picker bottom sheet ───────────────────────────────────────────

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Thư viện ảnh'),
              onTap: () => _pick(sheetCtx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => _pick(sheetCtx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.shape == ImagePickerButtonShape.circle;
    final isSquare = widget.shape == ImagePickerButtonShape.square;

    // Ưu tiên: bytes local → URL vừa upload → URL cũ từ prop
    final effectiveUrl = _uploadedUrl ?? widget.currentImageUrl;

    Widget preview;
    if (_localBytes != null) {
      // Hiện ngay từ bytes (không cần load network)
      preview = Image.memory(
        _localBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      preview = AppNetworkImage(
        url: effectiveUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        borderRadius: isCircle ? widget.size / 2 : 12,
        fallbackIcon: Icons.add_photo_alternate_outlined,
      );
    } else {
      preview = _placeholder();
    }

    final container = GestureDetector(
      onTap: _uploading ? null : _showSourcePicker,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Preview / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(isCircle ? widget.size / 2 : 12),
            child: _uploading
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Vẫn hiện ảnh cũ/local phía sau
                      preview,
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : preview,
          ),
          // Camera badge
          Positioned(
            right: isCircle ? 0 : 8,
            bottom: isCircle ? 0 : 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                  )
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );

    // Circle: bọc SizedBox cố định
    if (isCircle) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: container,
      );
    }

    // Rectangle / Square
    final fixedWidth = isSquare ? widget.size : double.infinity;
    final fixedHeight = isSquare ? widget.size : widget.size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        SizedBox(
          width: fixedWidth,
          height: fixedHeight,
          child: container,
        ),
      ],
    );
  }

  // ─── Placeholder ──────────────────────────────────────────────────────────

  Widget _placeholder() => Container(
        color: Colors.grey.shade800,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: widget.size * 0.3,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Nhấn để chọn',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
}
