import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Simulates client-side compression + upload (spec §6.4/§9): compression
/// ramps 0→1 over ~12 ticks, then upload ramps 0→1 over ~8 ticks, then the
/// video is added to the clinic library. [stepDelay] paces each tick; tests
/// pass [Duration.zero] to run the whole sequence instantly.
class UploadCubit extends Cubit<UploadState> {
  final LibraryRepository repository;
  final Duration stepDelay;

  String? _title;
  String? _bodyPart;
  int? _durationSec;
  String? _privateToPatientId;

  UploadCubit(this.repository, {this.stepDelay = const Duration(milliseconds: 60)})
      : super(const UploadIdle());

  Future<void> start({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
  }) {
    _title = title;
    _bodyPart = bodyPart;
    _durationSec = durationSec;
    _privateToPatientId = privateToPatientId;
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

  Future<void> _run() async {
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
