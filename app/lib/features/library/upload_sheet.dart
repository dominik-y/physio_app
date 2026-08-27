import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physio_app/data/demo_media_store.dart';
import 'package:physio_app/design_system/components.dart';
import 'package:physio_app/design_system/tokens.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/library/upload_cubit.dart';
import 'package:physio_app/l10n/body_parts.dart';
import 'package:physio_app/l10n/gen/app_localizations.dart';
import 'package:video_player/video_player.dart';

/// Demo cap (owner call 2026-08-25): imports are held in memory, so clips
/// are limited to 15 seconds. The Firebase pipeline lifts this.
const demoImportMaxSec = 15;

const _bodyPartOptions = ['Knee', 'Shoulder', 'Lower back', 'Neck'];
const _minDurationSec = 30;
const _maxDurationSec = 300; // 5:00
const _durationStepSec = 15;

/// Opens the film/upload sheet. Used from the Library ＋ button and inline
/// from the assign-flow video picker (spec §6.4), where [preselectPrivatePatientId]
/// pins the new clip to the patient already being assigned.
Future<void> showUploadSheet(BuildContext context, {String? preselectPrivatePatientId}) {
  final libraryRepository = context.read<LibraryRepository>();
  final mediaConfig = context.read<MediaConfig>();
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
      create: (_) =>
          UploadCubit(libraryRepository, uploader: mediaConfig.uploader),
      child: _UploadSheetContent(
          preselectPrivatePatientId: preselectPrivatePatientId,
          mediaConfig: mediaConfig),
    ),
  );
}

class _UploadSheetContent extends StatefulWidget {
  final String? preselectPrivatePatientId;
  final MediaConfig mediaConfig;
  const _UploadSheetContent(
      {this.preselectPrivatePatientId, required this.mediaConfig});

  @override
  State<_UploadSheetContent> createState() => _UploadSheetContentState();
}

class _UploadSheetContentState extends State<_UploadSheetContent> {
  final _titleController = TextEditingController();
  String _bodyPart = _bodyPartOptions.first;
  int _durationSec = 60;
  String? _privatePatientId;

  // Picked clip: the XFile (real uploads), a URL usable by the player
  // (demo import), and its probed duration. Null until a video is attached.
  XFile? _pickedFile;
  String? _pickedUrl;
  int? _pickedDurationSec;
  bool _probing = false;
  bool _pickTooLong = false;

  bool get _isRealUpload => widget.mediaConfig.uploader != null;
  int get _importMaxSec => widget.mediaConfig.importMaxSec;

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

  Future<void> _pickVideo(ImageSource source) async {
    final xfile = await ImagePicker().pickVideo(
      source: source,
      maxDuration: Duration(seconds: _importMaxSec),
    );
    if (xfile == null || !mounted) return;
    setState(() {
      _probing = true;
      _pickTooLong = false;
    });
    final url = xfile.path;
    final probed = await _probeDurationSec(url);
    if (!mounted) return;
    setState(() {
      _probing = false;
      // Cameras respect maxDuration; gallery picks may not — enforce here.
      if (probed != null && probed > _importMaxSec + 1) {
        _pickTooLong = true;
        _pickedFile = null;
        _pickedUrl = null;
        _pickedDurationSec = null;
      } else {
        _pickedFile = xfile;
        _pickedUrl = url;
        _pickedDurationSec = probed;
        if (probed != null && probed > 0) _durationSec = probed;
      }
    });
  }

  static Future<int?> _probeDurationSec(String url) async {
    final controller =
        (kIsWeb || url.startsWith('blob:') || url.startsWith('http'))
            ? VideoPlayerController.networkUrl(Uri.parse(url))
            : VideoPlayerController.file(File(url));
    try {
      await controller.initialize();
      return controller.value.duration.inSeconds;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  void _submit() {
    context.read<UploadCubit>().start(
          title: _titleController.text.trim(),
          bodyPart: _bodyPart,
          durationSec: _durationSec,
          privateToPatientId: _privatePatientId,
          file: _pickedFile,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadDone) {
          // Demo only: attach the locally picked clip to the freshly created
          // library entry so it plays for real everywhere in the demo. Real
          // uploads carry their Storage URL on the doc itself.
          final url = _pickedUrl;
          if (!_isRealUpload && url != null) {
            DemoMediaStore.instance.register(state.video.id, url);
          }
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
                Text(AppLocalizations.of(context).filmUploadVideo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
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
    final l = AppLocalizations.of(context);
    return [
      _VideoPickTile(
        pickedDurationSec: _pickedUrl == null ? null : _pickedDurationSec,
        probing: _probing,
        tooLong: _pickTooLong,
        tooLongMessage: _isRealUpload
            ? l.videoTooLongLimit(_importMaxSec)
            : l.videoTooLong,
        onPickGallery: () => _pickVideo(ImageSource.gallery),
        onPickCamera: kIsWeb ? null : () => _pickVideo(ImageSource.camera),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _titleController,
        decoration: InputDecoration(labelText: l.titleLabel),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(l.bodyPartLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final part in _bodyPartOptions)
            ChoiceChip(
              label: Text(localizedBodyPart(l, part),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              selected: _bodyPart == part,
              onSelected: (_) => setState(() => _bodyPart = part),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          Expanded(
            child: Text(l.durationLabel,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            decoration: InputDecoration(labelText: l.privateToPatient),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l.noneSharedLibrary,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
        label: l.compressAndUpload,
        // A real upload has nothing to send without a clip; demo entries may
        // stay title-only (placeholder playback).
        onPressed: _titleController.text.trim().isEmpty ||
                (_isRealUpload && _pickedFile == null)
            ? null
            : _submit,
      ),
      if (_isRealUpload && _pickedFile == null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(l.attachClipFirst,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    ];
  }

  List<Widget> _buildProgress(UploadState state) {
    final l = AppLocalizations.of(context);
    final compressProgress = state is UploadCompressing ? state.progress : 1.0;
    final uploadProgress = state is UploadUploading ? state.progress : 0.0;
    return [
      _ProgressStage(label: l.compressing, progress: compressProgress),
      const SizedBox(height: AppSpacing.md),
      _ProgressStage(label: l.uploading, progress: uploadProgress),
    ];
  }

  List<Widget> _buildFailed(UploadFailed state) {
    return [
      Text(
        state.message,
        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: AppSpacing.md),
      SecondaryButton(
          label: AppLocalizations.of(context).retry,
          onPressed: () => context.read<UploadCubit>().retry()),
    ];
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.accent, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Text(AppLocalizations.of(context).addedToLibrary,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Attach-a-clip tile: dashed-feel outline, gallery + camera actions, and
/// the attached/too-long states. Camera hidden on web.
class _VideoPickTile extends StatelessWidget {
  final int? pickedDurationSec;
  final bool probing;
  final bool tooLong;
  final String tooLongMessage;
  final VoidCallback onPickGallery;
  final VoidCallback? onPickCamera;

  const _VideoPickTile({
    required this.pickedDurationSec,
    required this.probing,
    required this.tooLong,
    required this.tooLongMessage,
    required this.onPickGallery,
    this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final attached = pickedDurationSec != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: attached ? const Color(0xFFEAF5FA) : AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
            color: attached ? AppColors.accent : AppColors.border,
            width: attached ? 1.4 : 1),
      ),
      child: probing
          ? const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      attached
                          ? Icons.check_circle_rounded
                          : Icons.videocam_outlined,
                      color: attached
                          ? AppColors.accentDeep
                          : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        attached
                            ? l.videoReady(formatDuration(pickedDurationSec!))
                            : l.pickVideoCta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (tooLong) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(tooLongMessage,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onPickGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                          attached ? l.replaceVideo : l.pickFromGallery),
                    ),
                    if (onPickCamera != null)
                      OutlinedButton.icon(
                        onPressed: onPickCamera,
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: Text(l.filmWithCamera),
                      ),
                  ],
                ),
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
