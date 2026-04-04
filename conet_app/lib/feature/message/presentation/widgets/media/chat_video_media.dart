import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatVideoMedia extends StatefulWidget {
  final String videoUrl;

  const ChatVideoMedia({super.key, required this.videoUrl});

  @override
  State<ChatVideoMedia> createState() => _ChatVideoMediaState();
}

class _ChatVideoMediaState extends State<ChatVideoMedia> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isMuted = true;
  bool _hasError = false;
  bool _isInitializing = false;
  bool _isVisible = false;

  Future<void> _initIfNeeded() async {
    if (_controller != null || _isInitializing || _hasError || !_isVisible) {
      return;
    }

    _isInitializing = true;
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) {
      if (mounted) {
        setState(() => _hasError = true);
      }
      _isInitializing = false;
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _isMuted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      _isInitializing = false;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisibleNow = info.visibleFraction > 0.05;
    if (isVisibleNow == _isVisible) return;

    _isVisible = isVisibleNow;

    if (_isVisible) {
      _initIfNeeded();
      return;
    }

    final controller = _controller;
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (!_isReady || controller == null) return;

    final nextMuted = !_isMuted;
    await controller.setVolume(nextMuted ? 0 : 1);
    if (!mounted) return;
    setState(() => _isMuted = nextMuted);
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (!_isReady || controller == null) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return VisibilityDetector(
      key: Key('chat-video-${widget.videoUrl}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildContent(colors),
    );
  }

  Widget _buildContent(AppSemanticColors colors) {
    if (_hasError) {
      return _MediaErrorCard(colors: colors);
    }

    if (!_isReady || _controller == null) {
      return Container(
        color: colors.backgroundSecondary,
        child: const Center(child: Loader()),
      );
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: _togglePlayPause,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colors.backgroundInverse,
              child: Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio > 0
                      ? controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            if (!controller.value.isPlaying)
              Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: colors.textInverse,
                  size: 56,
                ),
              ),
            if (_isMuted && controller.value.isPlaying)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.volume_off_rounded,
                  color: colors.textInverse,
                  size: 24,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: colors.backgroundInverse.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: colors.textInverse,
                        bufferedColor: colors.textInverse.withValues(
                          alpha: 0.6,
                        ),
                        backgroundColor: colors.textInverse.withValues(
                          alpha: 0.33,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(),
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: colors.textInverse,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _toggleMute,
                          child: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: colors.textInverse,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaErrorCard extends StatelessWidget {
  final AppSemanticColors colors;

  const _MediaErrorCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: colors.backgroundTertiary,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: colors.iconTertiary,
            size: 40,
          ),
        ),
      ),
    );
  }
}
