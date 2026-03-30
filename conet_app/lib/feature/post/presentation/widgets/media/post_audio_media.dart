import 'package:conet_app/core/theme/theme.dart';
import 'package:conet_app/feature/post/presentation/widgets/media/post_media_download_button.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PostAudioMedia extends StatefulWidget {
  final String audioUrl;

  const PostAudioMedia({super.key, required this.audioUrl});

  @override
  State<PostAudioMedia> createState() => _PostAudioMediaState();
}

class _PostAudioMediaState extends State<PostAudioMedia> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) return;
      setState(() => _duration = duration);
    });
  }

  Future<void> _init() async {
    try {
      final loadedDuration = await _player.setUrl(widget.audioUrl);
      if (!mounted) return;
      setState(() {
        _duration = loadedDuration ?? Duration.zero;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  Future<void> _togglePlayPause(PlayerState state) async {
    if (state.playing) {
      await _player.pause();
      return;
    }

    if (state.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  Future<void> _seekTo(double value) async {
    await _player.seek(Duration(milliseconds: value.toInt()));
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _fileLabel() {
    final uri = Uri.tryParse(widget.audioUrl);
    if (uri == null || uri.pathSegments.isEmpty) {
      return 'Audio file';
    }
    return uri.pathSegments.last;
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: semantic.backgroundSecondary,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 22,
                color: semantic.iconSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fileLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: semantic.textPrimary,
                  ),
                ),
              ),
              PostMediaDownloadButton(
                mediaUrl: widget.audioUrl,
                iconColor: semantic.iconPrimary,
                backgroundColor: semantic.surfaceBase,
              ),
            ],
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Unable to load audio.',
              style: textTheme.bodySmall?.copyWith(color: semantic.textError),
            ),
          ] else ...[
            const SizedBox(height: 10),
            StreamBuilder<Duration>(
              stream: _player.positionStream,
              initialData: Duration.zero,
              builder: (context, positionSnapshot) {
                final durationMs = _duration.inMilliseconds;
                final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
                final positionMs = positionSnapshot.data?.inMilliseconds ?? 0;
                final safeMs = durationMs > 0
                    ? positionMs.clamp(0, durationMs).toDouble()
                    : 0.0;

                return Column(
                  children: [
                    Slider(
                      value: safeMs,
                      max: maxMs,
                      onChanged: _duration == Duration.zero ? null : _seekTo,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(Duration(milliseconds: safeMs.toInt())),
                          style: textTheme.labelSmall?.copyWith(
                            color: semantic.textSecondary,
                          ),
                        ),
                        Text(
                          _format(_duration),
                          style: textTheme.labelSmall?.copyWith(
                            color: semantic.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state =
                    snapshot.data ?? PlayerState(false, ProcessingState.idle);
                return Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _togglePlayPause(state),
                      icon: Icon(
                        state.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(state.playing ? 'Pause' : 'Play'),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
