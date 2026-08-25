import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/library/upload_cubit.dart';

const _bodyPartOptions = ['Knee', 'Shoulder', 'Lower back', 'Neck'];
const _minDurationSec = 30;
const _maxDurationSec = 300; // 5:00
const _durationStepSec = 15;

/// Opens the film/upload sheet. Used from the Library ＋ button and inline
/// from the assign-flow video picker (spec §6.4), where [preselectPrivatePatientId]
/// pins the new clip to the patient already being assigned.
Future<void> showUploadSheet(BuildContext context, {String? preselectPrivatePatientId}) {
  final libraryRepository = context.read<LibraryRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    // The sheet route is pushed on the same Navigator as [context], so it
    // stays a descendant of the app-wide RepositoryProviders — PatientsRepository
    // is read directly by the content widget below.
    builder: (sheetContext) => BlocProvider(
      create: (_) => UploadCubit(libraryRepository),
      child: _UploadSheetContent(preselectPrivatePatientId: preselectPrivatePatientId),
    ),
  );
}

class _UploadSheetContent extends StatefulWidget {
  final String? preselectPrivatePatientId;
  const _UploadSheetContent({this.preselectPrivatePatientId});

  @override
  State<_UploadSheetContent> createState() => _UploadSheetContentState();
}

class _UploadSheetContentState extends State<_UploadSheetContent> {
  final _titleController = TextEditingController();
  String _bodyPart = _bodyPartOptions.first;
  int _durationSec = 60;
  String? _privatePatientId;

  @override
  void initState() {
    super.initState();
    _privatePatientId = widget.preselectPrivatePatientId;
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<UploadCubit>().start(
          title: _titleController.text.trim(),
          bodyPart: _bodyPart,
          durationSec: _durationSec,
          privateToPatientId: _privatePatientId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadDone) {
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Film / upload video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                if (state is UploadIdle) ..._buildForm(),
                if (state is UploadCompressing || state is UploadUploading)
                  ..._buildProgress(state),
                if (state is UploadFailed) ..._buildFailed(state),
                if (state is UploadDone) _buildDone(),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildForm() {
    return [
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(labelText: 'Title'),
      ),
      const SizedBox(height: AppSpacing.md),
      const Text('Body part', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final part in _bodyPartOptions)
            ChoiceChip(
              label: Text(part, maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: _bodyPart == part,
              onSelected: (_) => setState(() => _bodyPart = part),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          const Expanded(
            child: Text('Duration',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _durationSec > _minDurationSec
                ? () => setState(() => _durationSec -= _durationStepSec)
                : null,
          ),
          SizedBox(
            width: 44,
            child: Text(formatDuration(_durationSec), textAlign: TextAlign.center),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _durationSec < _maxDurationSec
                ? () => setState(() => _durationSec += _durationStepSec)
                : null,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      StreamBuilder<List<Patient>>(
        stream: context.read<PatientsRepository>().watchPatients(),
        builder: (context, snapshot) {
          final patients = snapshot.data ?? const <Patient>[];
          // Guard against the preselected/previously chosen id not being in
          // the items list yet (stream hasn't delivered its first value) —
          // Dropdown asserts its value must match an item.
          final displayedValue =
              patients.any((p) => p.id == _privatePatientId) ? _privatePatientId : null;
          return DropdownButtonFormField<String?>(
            value: displayedValue,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Private to patient (optional)'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None — shared library', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              for (final patient in patients)
                DropdownMenuItem<String?>(
                  value: patient.id,
                  child: Text(patient.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() => _privatePatientId = value),
          );
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(
        label: 'Compress & upload',
        onPressed: _titleController.text.trim().isEmpty ? null : _submit,
      ),
    ];
  }

  List<Widget> _buildProgress(UploadState state) {
    final compressProgress = state is UploadCompressing ? state.progress : 1.0;
    final uploadProgress = state is UploadUploading ? state.progress : 0.0;
    return [
      _ProgressStage(label: 'Compressing…', progress: compressProgress),
      const SizedBox(height: AppSpacing.md),
      _ProgressStage(label: 'Uploading…', progress: uploadProgress),
    ];
  }

  List<Widget> _buildFailed(UploadFailed state) {
    return [
      Text(
        state.message,
        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.md),
      SecondaryButton(label: 'Retry', onPressed: () => context.read<UploadCubit>().retry()),
    ];
  }

  Widget _buildDone() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.accent, size: 28),
          SizedBox(width: AppSpacing.sm),
          Text('Added to library', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProgressStage extends StatelessWidget {
  final String label;
  final double progress;
  const _ProgressStage({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('${(progress * 100).round()}%', style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}
