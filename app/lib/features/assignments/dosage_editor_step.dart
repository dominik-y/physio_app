import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/features/assignments/assign_flow_bloc.dart';

const _dayLabels = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

/// Dosage editor (spec §6.3, plan amendment 10): name + days header, a
/// reorderable exercise list, then a footer carrying the save-as-template
/// switch and the §4.6 total-exercise confirm guard.
class DosageEditorStep extends StatefulWidget {
  const DosageEditorStep({super.key});

  @override
  State<DosageEditorStep> createState() => _DosageEditorStepState();
}

class _DosageEditorStepState extends State<DosageEditorStep> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: context.read<AssignFlowBloc>().state.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssignFlowBloc>();
    return BlocConsumer<AssignFlowBloc, AssignFlowState>(
      listenWhen: (previous, current) => current.name != _nameController.text && previous.name != current.name,
      listener: (context, state) => _nameController.text = state.name,
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Protocol name'),
                    onChanged: (value) => bloc.add(NameChanged(value)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final entry in _dayLabels.entries)
                        FilterChip(
                          label: Text(entry.value),
                          selected: state.daysOfWeek.contains(entry.key),
                          onSelected: (_) => bloc.add(DaysToggled(entry.key)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty
                  ? const EmptyState(
                      icon: Icons.playlist_remove,
                      message: 'No exercises',
                      detail: 'Add at least one to assign.',
                    )
                  : ReorderableListView(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      onReorder: (oldIndex, newIndex) => bloc.add(ItemsReordered(oldIndex, newIndex)),
                      children: [
                        for (var i = 0; i < state.items.length; i++)
                          _ExerciseCard(
                            key: ValueKey(state.items[i].videoId),
                            index: i,
                            item: state.items[i],
                            bloc: bloc,
                          ),
                      ],
                    ),
            ),
            _Footer(state: state, bloc: bloc),
          ],
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final ExerciseItem item;
  final AssignFlowBloc bloc;

  const _ExerciseCard({super.key, required this.index, required this.item, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(Icons.drag_indicator, color: AppColors.textMuted),
                  ),
                ),
                VideoThumb(bodyPart: item.bodyPart),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(item.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => bloc.add(ItemRemoved(item.videoId)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: DosagePill(
                    label: 'sets',
                    value: '${item.sets}×',
                    overridden: item.overridden,
                    onTap: () => _editValue(
                      context,
                      title: 'Sets',
                      value: item.sets,
                      min: 1,
                      step: 1,
                      format: (v) => '$v',
                      onChanged: (v) => bloc.add(DosageChanged(item.videoId, sets: v)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: DosagePill(
                    label: 'reps',
                    value: '${item.reps}',
                    overridden: item.overridden,
                    onTap: () => _editValue(
                      context,
                      title: 'Reps',
                      value: item.reps,
                      min: 1,
                      step: 1,
                      format: (v) => '$v',
                      onChanged: (v) => bloc.add(DosageChanged(item.videoId, reps: v)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: DosagePill(
                    label: 'hold',
                    value: item.holdSec == 0 ? '—' : formatDuration(item.holdSec),
                    overridden: item.overridden,
                    onTap: () => _editValue(
                      context,
                      title: 'Hold',
                      value: item.holdSec,
                      min: 0,
                      step: 5,
                      format: (v) => v == 0 ? 'No hold' : formatDuration(v),
                      onChanged: (v) => bloc.add(DosageChanged(item.videoId, holdSec: v)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editValue(
  BuildContext context, {
  required String title,
  required int value,
  required int min,
  required int step,
  required String Function(int) format,
  required ValueChanged<int> onChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var current = value;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: current > min ? () => setState(() => current -= step) : null,
                ),
                SizedBox(
                  width: 84,
                  child: Text(format(current),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => current += step),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  onChanged(current);
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Footer extends StatelessWidget {
  final AssignFlowState state;
  final AssignFlowBloc bloc;

  const _Footer({required this.state, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inset divider keeps the screen's 16px margin rhythm.
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Save as template'),
            value: state.saveAsTemplate,
            onChanged: (_) => bloc.add(const SaveAsTemplateToggled()),
          ),
          if (state.confirmArmed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '${state.patientName} will have ${state.existingDailyTotal + state.items.length} exercises daily',
                maxLines: 2,
                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          PrimaryButton(
            label: state.confirmArmed ? 'Confirm anyway' : 'Assign to ${state.patientName}',
            onPressed: state.items.isEmpty ? null : () => bloc.add(const SubmitPressed()),
          ),
        ],
      ),
    );
  }
}
