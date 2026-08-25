import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/library/library_bloc.dart';
import 'package:physio_app/features/library/upload_sheet.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryBloc(context.read<LibraryRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Film / upload video',
              onPressed: () => showUploadSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<LibraryBloc, Map<String, List<VideoItem>>>(
          builder: (context, grouped) {
            if (grouped.isEmpty) {
              return const EmptyState(
                icon: Icons.video_library_outlined,
                message: 'No videos yet',
                detail: 'Film or upload your first exercise video.',
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                for (final section in grouped.entries) ...[
                  SectionHeader(title: section.key),
                  for (final video in section.value) ...[
                    _LibraryRow(video: video),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final VideoItem video;
  const _LibraryRow({required this.video});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          VideoThumb(bodyPart: video.bodyPart),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDuration(video.durationSec)} · used by ${video.usageCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (video.isPrivate) ...[
            const SizedBox(width: AppSpacing.sm),
            const StatusChip.private(),
          ],
        ],
      ),
    );
  }
}
