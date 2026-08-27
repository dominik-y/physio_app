import 'package:flutter/material.dart';
import 'package:physio_app/app/session_scope.dart';
import 'package:physio_app/data/demo_media_store.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/fullscreen_video_page.dart';
import 'package:physio_app/design_system/real_video_player.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Playback state handed back by the placeholder's fullscreen stage.
typedef _DemoPlayback = ({double progress, bool playing});

/// Demo stand-in for real video playback (spec §15.1): a poster gradient with
/// play/pause and a progress bar animated over the real duration. When the
/// video id has locally imported media (DemoMediaStore), a real player is
/// rendered instead — same chrome, same callbacks.
class DemoVideoPlayer extends StatefulWidget {
  final String title;
  final String bodyPart;
  final int durationSec;
  final bool autoplay;

  /// Library video id; used to look up locally imported clips.
  final String? videoId;

  /// Real playback URL (Firebase flavor: Storage download URL snapshotted
  /// on the video doc / assignment item). Wins over the DemoMediaStore
  /// lookup; when both are null in a signed-in session the player shows
  /// "video unavailable" instead of the demo placeholder.
  final String? mediaUrl;

  /// When true the player expands to fill its parent (session player, where
  /// the video is the dominant object) instead of locking to 16:9.
  final bool fill;
  final VoidCallback? onCompleted;

  /// Fullscreen hosting: exit control instead of enter, progress carried in.
  final bool isFullscreen;
  final double initialProgress;

  const DemoVideoPlayer({
    super.key,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
    this.videoId,
    this.mediaUrl,
    this.autoplay = false,
    this.fill = false,
    this.onCompleted,
    this.isFullscreen = false,
    this.initialProgress = 0,
  });

  @override
  State<DemoVideoPlayer> createState() => _DemoVideoPlayerState();
}

class _DemoVideoPlayerState extends State<DemoVideoPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSec.clamp(1, 3600)),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted?.call();
    });
    _controller.value = widget.initialProgress.clamp(0.0, 1.0);
    if (widget.autoplay) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      if (_controller.value >= 1.0) _controller.value = 0;
      _controller.forward();
    }
    setState(() {});
  }

  Future<void> _enterFullscreen() async {
    final wasPlaying = _controller.isAnimating;
    final progress = _controller.value;
    _controller.stop();
    final result = await FullscreenVideoPage.open<_DemoPlayback>(
      context,
      (_) => DemoVideoPlayer(
        title: widget.title,
        bodyPart: widget.bodyPart,
        durationSec: widget.durationSec,
        fill: true,
        isFullscreen: true,
        autoplay: wasPlaying,
        initialProgress: progress,
      ),
    );
    if (!mounted) return;
    if (result != null) {
      _controller.value = result.progress;
      if (result.playing) _controller.forward();
    } else if (wasPlaying) {
      _controller.forward();
    }
    setState(() {});
  }

  void _exitFullscreen() {
    FullscreenVideoPage.exit<_DemoPlayback>(
        context, (progress: _controller.value, playing: _controller.isAnimating));
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl =
        widget.mediaUrl ?? DemoMediaStore.instance.urlFor(widget.videoId);
    if (mediaUrl != null) {
      return RealVideoPlayer(
        url: mediaUrl,
        autoplay: widget.autoplay,
        fill: widget.fill,
        onCompleted: widget.onCompleted,
      );
    }
    // Signed-in session with no URL: the animated demo placeholder would
    // fake playback of a real product — show the honest state instead.
    if (SessionScope.maybeOf(context) != null) {
      final stage = Container(
        color: AppColors.videoBg,
        child: const VideoUnavailableStage(),
      );
      return widget.fill
          ? stage
          : AspectRatio(aspectRatio: 16 / 9, child: stage);
    }
    final player = Container(
      decoration: const BoxDecoration(color: AppColors.videoBg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.55,
            child: VideoThumb(
              bodyPart: widget.bodyPart,
              width: double.infinity,
              height: double.infinity,
              playIcon: false,
            ),
          ),
          Positioned(
            left: 14,
            top: 12,
            right: 14,
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onAccent.withOpacity(0.9),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => IconButton(
                onPressed: _toggle,
                iconSize: 58,
                tooltip: _controller.isAnimating
                    ? AppLocalizations.of(context).pauseVideo
                    : AppLocalizations.of(context).playVideo,
                icon: Icon(
                  _controller.isAnimating
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: AppColors.onAccent.withOpacity(0.92),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => LinearProgressIndicator(
                value: _controller.value,
                minHeight: 4,
                backgroundColor: AppColors.onAccent.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accentSoft),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final elapsed =
                        (_controller.value * widget.durationSec).round();
                    return Text(
                      '${formatDuration(elapsed)} / ${formatDuration(widget.durationSec)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onAccent.withOpacity(0.8),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed:
                      widget.isFullscreen ? _exitFullscreen : _enterFullscreen,
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
    return widget.fill
        ? player
        : AspectRatio(aspectRatio: 16 / 9, child: player);
  }
}
