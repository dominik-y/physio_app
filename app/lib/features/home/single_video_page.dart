import 'package:flutter/material.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/demo_video_player.dart';
import 'package:physio_app/design_system/tokens.dart';

/// Full-screen browse for a single (non-protocol) video (spec §5.1
/// "Also assigned"). Browsed only — no completion is recorded here (§4.6
/// critique amendment 3: singles never enter the guided session).
class SingleVideoPage extends StatelessWidget {
  final String title;
  final String bodyPart;
  final int durationSec;

  const SingleVideoPage({
    super.key,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.videoBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.onAccent),
                tooltip: 'Close',
              ),
            ),
            DemoVideoPlayer(
              title: title,
              bodyPart: bodyPart,
              durationSec: durationSec,
              autoplay: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onAccent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatDuration(durationSec),
                    style: TextStyle(fontSize: 14, color: AppColors.onAccent.withOpacity(0.65)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
