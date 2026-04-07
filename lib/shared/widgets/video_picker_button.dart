import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cinema_booking_system_app/core/utils/media_upload_helper.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

/// Widget chọn & upload video — dùng cho trailer phim
///
/// ```dart
/// VideoPickerButton(
///   label: 'Trailer phim',
///   currentVideoUrl: _trailerUrl,
///   onUploaded: (url) => setState(() => _trailerUrl = url),
/// )
/// ```
class VideoPickerButton extends StatefulWidget {
  final String? currentVideoUrl;
  final String label;
  final Duration? maxDuration;
  final void Function(String url) onUploaded;
  final void Function(String error)? onError;

  const VideoPickerButton({
    super.key,
    required this.label,
    required this.onUploaded,
    this.currentVideoUrl,
    this.maxDuration = const Duration(minutes: 10),
    this.onError,
  });

  @override
  State<VideoPickerButton> createState() => _VideoPickerButtonState();
}

class _VideoPickerButtonState extends State<VideoPickerButton> {
  bool _uploading = false;

  Future<void> _pick(BuildContext sheetContext, ImageSource source) async {
    // Lưu messenger trước khi pop sheet (tránh dùng context sau async gap)
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(sheetContext, rootNavigator: true).pop();

    final url = await MediaUploadHelper.pickAndUploadVideo(
      source: source,
      maxDuration: widget.maxDuration,
      onUploading: (v) {
        if (mounted) setState(() => _uploading = v);
      },
      onError: widget.onError ??
          (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Lỗi tải video lên: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          },
    );
    if (url != null && mounted) widget.onUploaded(url);
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Thư viện video'),
              onTap: () => _pick(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Quay video'),
              onTap: () => _pick(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.currentVideoUrl != null &&
        widget.currentVideoUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _uploading ? null : _showSourcePicker,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasVideo ? AppColors.primary : Colors.grey.shade700,
            width: hasVideo ? 2 : 1,
          ),
        ),
        child: _uploading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Đang tải video lên...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasVideo ? Icons.check_circle_outline : Icons.video_file_outlined,
                    size: 32,
                    color: hasVideo ? AppColors.primary : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: hasVideo ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasVideo ? 'Đã tải lên • Nhấn để thay đổi' : 'Nhấn để chọn video',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
