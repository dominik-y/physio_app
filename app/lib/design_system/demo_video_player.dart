import 'package:flutter/material.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';

/// Demo stand-in for real video playback (spec §15.1): a poster gradient with
/// play/pause and a progress bar animated over the real duration. A future
/// Firebase-backed player replaces this widget without touching callers.
class DemoVideoPlayer extends StatefulWidget {
  final String title;
  final String bodyPart;
  final int durationSec;
  final bool autoplay;

  /// When true the player expands to fill its parent (session player, where
  /// the video is the dominant object) instead of locking to 16:9.
  final bool fill;
  final VoidCallback? onCompleted;

  const DemoVideoPlayer({
    super.key,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
    this.autoplay = false,
    this.fill = false,
    this.onCompleted,
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

  @override
  Widget build(BuildContext context) {
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
            child: IconButton(
              onPressed: _toggle,
              iconSize: 58,
              icon: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Icon(
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
            right: 12,
            bottom: 10,
            child: AnimatedBuilder(
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
          ),
        ],
      ),
    );
    return widget.fill
        ? player
        : AspectRatio(aspectRatio: 16 / 9, child: player);
  }
}
