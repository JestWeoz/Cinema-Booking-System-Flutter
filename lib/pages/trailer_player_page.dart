import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class TrailerPlayerPage extends StatefulWidget {
  final String url;
  final String title;

  const TrailerPlayerPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<TrailerPlayerPage> createState() => _TrailerPlayerPageState();
}

class _TrailerPlayerPageState extends State<TrailerPlayerPage> {
  late final VideoPlayerController _controller;
  Timer? _progressTimer;
  bool _ready = false;
  String? _error;
  Duration _lastPosition = Duration.zero;
  bool _lastIsPlaying = false;

  void _refreshProgress() {
    if (!mounted || !_controller.value.isInitialized) {
      return;
    }

    final value = _controller.value;
    final shouldRefresh =
        value.position != _lastPosition || value.isPlaying != _lastIsPlaying;
    _lastPosition = value.position;
    _lastIsPlaying = value.isPlaying;

    if (shouldRefresh) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.play();
      if (!mounted) {
        return;
      }
      _startProgressTimer();
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_controller.value.isInitialized) {
      return;
    }
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _refreshProgress();
    });
  }

  String _format(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Không thể phát trailer\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            )
          : !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controller),
                              AnimatedOpacity(
                                opacity: value.isPlaying ? 0 : 1,
                                duration: const Duration(milliseconds: 180),
                                child: IconButton(
                                  onPressed: _togglePlay,
                                  iconSize: 72,
                                  color: Colors.white,
                                  icon: const Icon(Icons.play_circle_fill_rounded),
                                ),
                              ),
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: _togglePlay,
                                  behavior: HitTestBehavior.opaque,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        border: Border(
                          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: VideoProgressColors(
                              playedColor: AppColors.primary,
                              bufferedColor: AppColors.primary.withValues(alpha: 0.35),
                              backgroundColor: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _togglePlay,
                                icon: Icon(
                                  value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _format(value.position),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const Text(' / ', style: TextStyle(color: Colors.white38)),
                              Text(
                                _format(value.duration),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  final target = value.position + const Duration(seconds: 10);
                                  _controller.seekTo(target < value.duration ? target : value.duration);
                                },
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
