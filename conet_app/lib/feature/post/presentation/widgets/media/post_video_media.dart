import 'package:conet_app/core/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostVideoMedia extends StatefulWidget {
  final String videoUrl;

  const PostVideoMedia({super.key, required this.videoUrl});

  @override
  State<PostVideoMedia> createState() => _PostVideoMediaState();
}

class _PostVideoMediaState extends State<PostVideoMedia> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) {
      setState(() => _hasError = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _isMuted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
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
    if (_hasError) {
      return const _MediaErrorCard();
    }

    if (!_isReady || _controller == null) {
      return Container(
        color: Colors.black12,
        child: const Center(child: Loader()),
      );
    }

    final controller = _controller!;
    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
          if (_isMuted)
            const Center(
              child: Icon(
                Icons.volume_off_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0x66000000),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Color(0x99FFFFFF),
                      backgroundColor: Color(0x55FFFFFF),
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _toggleMute,
                        child: Icon(
                          _isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
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
    );
  }
}

class _MediaErrorCard extends StatelessWidget {
  const _MediaErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 44),
      ),
    );
  }
}
