import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/fullscreen_video_page.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';
import 'package:video_player/video_player.dart';

/// Playback state handed back when a fullscreen stage closes.
typedef PlaybackState = ({Duration position, bool playing});

/// Plays a locally imported clip (DemoMediaStore) with the same minimal
/// chrome as DemoVideoPlayer: dark stage, center play/pause, progress bar.
class RealVideoPlayer extends StatefulWidget {
  final String url;
  final bool autoplay;
  final bool fill;
  final VoidCallback? onCompleted;

  /// True when hosted inside [FullscreenVideoPage]: shows an exit control
  /// instead of the fullscreen one and pops with the playback state.
  final bool isFullscreen;
  final Duration startAt;
  final bool startPlaying;

  const RealVideoPlayer({
    super.key,
    required this.url,
    this.autoplay = false,
    this.fill = false,
    this.onCompleted,
    this.isFullscreen = false,
    this.startAt = Duration.zero,
    this.startPlaying = false,
  });

  @override
  State<RealVideoPlayer> createState() => _RealVideoPlayerState();
}

class _RealVideoPlayerState extends State<RealVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    // 'asset:' = bundled clip (seeded demo footage); blob/http = web pick;
    // anything else is a device file path from the image picker. On web the
    // video_player plugin has no asset source — assets are fetched over HTTP
    // from the bundle's assets/ directory instead.
    final url = widget.url;
    _controller = url.startsWith('asset:')
        ? (kIsWeb
            ? VideoPlayerController.networkUrl(
                Uri.parse('assets/${url.substring(6)}'))
            : VideoPlayerController.asset(url.substring(6)))
        : (kIsWeb || url.startsWith('blob:') || url.startsWith('http'))
            ? VideoPlayerController.networkUrl(Uri.parse(url))
            : VideoPlayerController.file(File(url));
    _controller.initialize().then((_) async {
      if (!mounted) return;
      if (widget.startAt > Duration.zero) {
        await _controller.seekTo(widget.startAt);
      }
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.autoplay || widget.startPlaying) _controller.play();
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    final v = _controller.value;
    if (!_completedFired &&
        v.isInitialized &&
        !v.isPlaying &&
        v.duration > Duration.zero &&
        v.position >= v.duration) {
      _completedFired = true;
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enterFullscreen() async {
    final wasPlaying = _controller.value.isPlaying;
    final position = _controller.value.position;
    _controller.pause();
    final result = await FullscreenVideoPage.open<PlaybackState>(
      context,
      (_) => RealVideoPlayer(
        url: widget.url,
        fill: true,
        isFullscreen: true,
        startAt: position,
        startPlaying: wasPlaying,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      await _controller.seekTo(result.position);
      if (result.playing) _controller.play();
    } else if (wasPlaying) {
      _controller.play();
    }
    setState(() {});
  }

  void _exitFullscreen() {
    final v = _controller.value;
    FullscreenVideoPage.exit<PlaybackState>(
        context, (position: v.position, playing: v.isPlaying));
  }

  void _toggle() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      if (_controller.value.position >= _controller.value.duration) {
        _controller.seekTo(Duration.zero);
      }
      _completedFired = false;
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stage = Container(
      color: AppColors.videoBg,
      child: !_ready
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.accentSoft),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0
                        ? 16 / 9
                        : _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                Center(
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, VideoPlayerValue v, __) => AnimatedOpacity(
                      opacity: v.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        onPressed: _toggle,
                        iconSize: 58,
                        tooltip: v.isPlaying
                            ? AppLocalizations.of(context).pauseVideo
                            : AppLocalizations.of(context).playVideo,
                        icon: Icon(
                          v.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: AppColors.onAccent.withOpacity(0.92),
                        ),
                      ),
                    ),
                  ),
                ),
                // Full-surface tap target so pausing doesn't need the icon.
                Positioned.fill(
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent, onTap: _toggle),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    padding: EdgeInsets.zero,
                    colors: VideoProgressColors(
                      playedColor: AppColors.accentSoft,
                      bufferedColor: AppColors.onAccent.withOpacity(0.35),
                      backgroundColor: AppColors.onAccent.withOpacity(0.2),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (_, VideoPlayerValue v, __) => Text(
                          '${formatDuration(v.position.inSeconds)} / ${formatDuration(v.duration.inSeconds)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onAccent.withOpacity(0.8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.isFullscreen
                            ? _exitFullscreen
                            : _enterFullscreen,
                        tooltip: widget.isFullscreen
                            ? AppLocalizations.of(context).exitFullscreenTooltip
                            : AppLocalizations.of(context).fullscreenTooltip,
                        iconSize: 22,
                        icon: Icon(
                          widget.isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: AppColors.onAccent.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
    return widget.fill ? stage : AspectRatio(aspectRatio: 16 / 9, child: stage);
  }
}
