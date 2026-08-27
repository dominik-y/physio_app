import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';

sealed class UploadState {
  const UploadState();
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadCompressing extends UploadState {
  final double progress;
  const UploadCompressing(this.progress);
}

class UploadUploading extends UploadState {
  final double progress;
  const UploadUploading(this.progress);
}

class UploadDone extends UploadState {
  final VideoItem video;
  const UploadDone(this.video);
}

class UploadFailed extends UploadState {
  final String message;
  const UploadFailed(this.message);
}

/// Drives the compress→upload→add-to-library sequence. With no [uploader]
/// (demo mode, the pitch build) the stages are simulated: compression ramps
/// 0→1 over ~12 ticks, upload over ~8, then the video is added — behavior
/// unchanged, including the "!"-title failure trigger. With an [uploader]
/// (Firebase flavor) the real pipeline runs and its progress drives the same
/// states. [stepDelay] paces simulation ticks; tests pass [Duration.zero].
class UploadCubit extends Cubit<UploadState> {
  final LibraryRepository repository;
  final MediaUploader? uploader;
  final Duration stepDelay;

  String? _title;
  String? _bodyPart;
  int? _durationSec;
  String? _privateToPatientId;
  XFile? _file;

  UploadCubit(this.repository,
      {this.uploader, this.stepDelay = const Duration(milliseconds: 60)})
      : super(const UploadIdle());

  Future<void> start({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
    XFile? file,
  }) {
    _title = title;
    _bodyPart = bodyPart;
    _durationSec = durationSec;
    _privateToPatientId = privateToPatientId;
    _file = file;
    return _run();
  }

  /// Re-runs the whole compress→upload sequence with the args from the last
  /// [start] call (spec §12: retryable without re-entering the form).
  Future<void> retry() {
    if (_title == null) return Future.value();
    return _run();
  }

  static const _compressTicks = 12;
  static const _uploadTicks = 8;

  Future<void> _run() =>
      uploader == null ? _runSimulated() : _runReal(uploader!);

  Future<void> _runReal(MediaUploader uploader) async {
    final file = _file;
    if (file == null) {
      // The sheet disables submit until a clip is attached — reaching here
      // without one is a wiring bug, surfaced instead of silently ignored.
      emit(const UploadFailed('Najprije odaberite ili snimite video.'));
      return;
    }
    try {
      final media = await uploader.upload(
        file: file,
        onCompress: (p) {
          if (!isClosed) emit(UploadCompressing(p));
        },
        onUpload: (p) {
          if (!isClosed) emit(UploadUploading(p));
        },
      );
      if (isClosed) return;
      final result = await repository.addVideo(
        title: _title!,
        bodyPart: _bodyPart!,
        durationSec: _durationSec!,
        privateToPatientId: _privateToPatientId,
        media: media,
      );
      if (isClosed) return;
      result.when(
        ok: (video) => emit(UploadDone(video)),
        err: (message) => emit(UploadFailed(message)),
      );
    } on MediaUploadException catch (e) {
      if (isClosed) return;
      emit(UploadFailed(e.message));
    } catch (e) {
      if (isClosed) return;
      emit(UploadFailed('$e'));
    }
  }

  Future<void> _runSimulated() async {
    for (var i = 1; i <= _compressTicks; i++) {
      if (isClosed) return;
      emit(UploadCompressing(i / _compressTicks));
      await Future<void>.delayed(stepDelay);
    }

    // Demo-only hidden trigger (not surfaced in any UI copy): a title ending
    // in '!' always fails at ~60% upload, so the sheet's retry affordance has
    // something to showcase.
    final failsAtTick =
        _title!.trim().endsWith('!') ? (_uploadTicks * 0.6).round() : null;

    for (var i = 1; i <= _uploadTicks; i++) {
      if (isClosed) return;
      if (failsAtTick != null && i == failsAtTick) {
        emit(const UploadFailed('Upload failed — connection dropped'));
        return;
      }
      emit(UploadUploading(i / _uploadTicks));
      await Future<void>.delayed(stepDelay);
    }

    final result = await repository.addVideo(
      title: _title!,
      bodyPart: _bodyPart!,
      durationSec: _durationSec!,
      privateToPatientId: _privateToPatientId,
    );
    if (isClosed) return;
    result.when(
      ok: (video) => emit(UploadDone(video)),
      err: (message) => emit(UploadFailed(message)),
    );
  }
}
