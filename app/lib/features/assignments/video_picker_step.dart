import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/assignments/assign_flow_bloc.dart';
import 'package:physio_app/features/library/upload_sheet.dart';

const _fixedSectionOrder = ['Knee', 'Shoulder', 'Lower back', 'Neck'];

Map<String, List<VideoItem>> _groupByBodyPart(List<VideoItem> videos) {
  final byBodyPart = <String, List<VideoItem>>{};
  for (final video in videos) {
    (byBodyPart[video.bodyPart] ??= []).add(video);
  }
  for (final section in byBodyPart.values) {
    section.sort((a, b) => a.title.compareTo(b.title));
  }
  final others = byBodyPart.keys.where((k) => !_fixedSectionOrder.contains(k)).toList()..sort();
  final order = [..._fixedSectionOrder.where(byBodyPart.containsKey), ...others];
  return {for (final section in order) section: byBodyPart[section]!};
}

/// Video picker (spec §4.5, §6.4): multi-select for custom protocols,
/// single-select for the single-video path. Grouped by body part like the
/// library. "Film new" opens the inline upload sheet (spec §6.4).
class VideoPickerStep extends StatelessWidget {
  const VideoPickerStep({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssignFlowBloc>();
    return BlocBuilder<AssignFlowBloc, AssignFlowState>(
      builder: (context, state) {
        final grouped = _groupByBodyPart(state.videos);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Pick videos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    onPressed: () => showUploadSheet(context),
                    child: const Text('Film new'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: grouped.isEmpty
                  ? const EmptyState(
                      icon: Icons.video_library_outlined,
                      message: 'No videos yet',
                      detail: 'Film one to get started.',
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      children: [
                        for (final section in grouped.entries) ...[
                          SectionHeader(title: section.key),
                          for (final video in section.value) ...[
                            _VideoRow(
                              video: video,
                              selected: state.selectedVideoIds.contains(video.id),
                              alreadyAdded: state.items.any((i) => i.videoId == video.id),
                              onTap: () => bloc.add(PickerSelectionToggled(video.id)),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
            ),
            _PickerFooter(state: state, bloc: bloc),
          ],
        );
      },
    );
  }
}

class _VideoRow extends StatelessWidget {
  final VideoItem video;
  final bool selected;
  final bool alreadyAdded;
  final VoidCallback onTap;

  const _VideoRow({
    required this.video,
    required this.selected,
    required this.alreadyAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = AppCard(
      onTap: alreadyAdded ? null : onTap,
      child: Row(
        children: [
          VideoThumb(bodyPart: video.bodyPart),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(video.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(formatDuration(video.durationSec),
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    if (video.isPrivate) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Flexible(child: StatusChip.private()),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            alreadyAdded || selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: alreadyAdded ? AppColors.textMuted : (selected ? AppColors.accent : AppColors.border),
          ),
        ],
      ),
    );
    return alreadyAdded ? Opacity(opacity: 0.55, child: row) : row;
  }
}

class _PickerFooter extends StatelessWidget {
  final AssignFlowState state;
  final AssignFlowBloc bloc;

  const _PickerFooter({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final n = state.selectedVideoIds.length;
    final single = state.type == AssignmentType.single;
    final label = single ? 'Send to ${state.patientName}' : 'Add $n exercises';
    final enabled = single ? n == 1 : n > 0;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: PrimaryButton(
        label: label,
        onPressed: enabled ? () => bloc.add(const PickerConfirmed()) : null,
      ),
    );
  }
}
