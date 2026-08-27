import 'package:flutter/material.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/demo_video_player.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';

/// Full-screen browse for a single (non-protocol) video (spec §5.1
/// "Also assigned"). Browsed only — no completion is recorded here (§4.6
/// critique amendment 3: singles never enter the guided session).
class SingleVideoPage extends StatelessWidget {
  final String title;
  final String bodyPart;
  final int durationSec;
  final String? videoId;
  final String? mediaUrl;

  const SingleVideoPage({
    super.key,
    required this.title,
    required this.bodyPart,
    required this.durationSec,
    this.videoId,
    this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.videoBg,
      body: SafeArea(
        // Scrollable so a transient landscape frame (fullscreen-exit
        // rotation) can never paint an overflow stripe.
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.onAccent),
                tooltip: AppLocalizations.of(context).close,
              ),
            ),
            DemoVideoPlayer(
              title: title,
              bodyPart: bodyPart,
              durationSec: durationSec,
              videoId: videoId,
              mediaUrl: mediaUrl,
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
        )),
      ),
    );
  }
}
