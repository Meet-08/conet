import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:conet_app/feature/message/presentation/widgets/media/chat_media_download_button.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ChatAudioMedia extends StatefulWidget {
  final String audioUrl;

  const ChatAudioMedia({super.key, required this.audioUrl});

  @override
  State<ChatAudioMedia> createState() => _ChatAudioMediaState();
}

class _ChatAudioMediaState extends State<ChatAudioMedia> {
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
    final colors = Theme.of(context).extension<AppSemanticColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack_rounded,
                size: 22,
                color: colors.iconPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fileLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              ChatMediaDownloadButton(
                mediaUrl: widget.audioUrl,
                iconColor: colors.textPrimary,
                backgroundColor: colors.backgroundPrimary,
              ),
            ],
          ),
          if (_hasError) ...[
            const SizedBox(height: 12),
            Text(
              'Unable to load audio.',
              style: AppTextStyles.caption.copyWith(color: colors.textError),
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
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          _format(_duration),
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing ?? false;

                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 40,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.iconBrand,
                              ),
                            ),
                          );
                        } else if (processingState ==
                            ProcessingState.completed) {
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _player.seek(Duration.zero);
                                _player.play();
                              },
                              icon: Icon(
                                Icons.replay_rounded,
                                color: colors.iconPrimary,
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _togglePlayPause(
                                playerState ??
                                    PlayerState(false, ProcessingState.idle),
                              ),
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                                size: 40,
                                color: colors.iconBrand,
                              ),
                            ),
                          );
                        }
                      },
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
