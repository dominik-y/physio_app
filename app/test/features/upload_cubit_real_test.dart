import 'package:bloc_test/bloc_test.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/result.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/domain/media_uploader.dart';
import 'package:physio_app/domain/models.dart';
import 'package:physio_app/domain/repositories.dart';
import 'package:physio_app/features/library/upload_cubit.dart';

/// Scripted uploader: emits fixed compress/upload progress, then either a
/// result or a scripted failure. Never touches plugins.
class FakeMediaUploader implements MediaUploader {
  MediaUploadException? failure;
  int uploadCalls = 0;
  XFile? lastFile;

  static const result = MediaUploadResult(
    videoId: 'vid-storage-1',
    mediaUrl: 'https://storage.example/video.mp4',
    posterUrl: 'https://storage.example/poster.jpg',
    storagePath: 'clinics/tendo/videos/vid-storage-1/video.mp4',
  );

  @override
  Future<MediaUploadResult> upload({
    required XFile file,
    void Function(double progress)? onCompress,
    void Function(double progress)? onUpload,
  }) async {
    uploadCalls++;
    lastFile = file;
    onCompress?.call(0.5);
    onCompress?.call(1.0);
    if (failure != null && failure!.stage == MediaUploadStage.compress) {
      throw failure!;
    }
    onUpload?.call(0.5);
    if (failure != null) throw failure!;
    onUpload?.call(1.0);
    return result;
  }
}

/// Delegates to the demo repository but records the media argument, which
/// the demo impl deliberately ignores.
class _RecordingLibraryRepository implements LibraryRepository {
  final LibraryRepository inner;
  MediaUploadResult? lastMedia;
  _RecordingLibraryRepository(this.inner);

  @override
  Stream<List<VideoItem>> watchVideos() => inner.watchVideos();

  @override
  Future<Result<VideoItem>> addVideo({
    required String title,
    required String bodyPart,
    required int durationSec,
    String? privateToPatientId,
    MediaUploadResult? media,
  }) {
    lastMedia = media;
    return inner.addVideo(
      title: title,
      bodyPart: bodyPart,
      durationSec: durationSec,
      privateToPatientId: privateToPatientId,
      media: media,
    );
  }
}

void main() {
  final now = DateTime(2026, 8, 27, 9, 30);
  final clip = XFile('/tmp/clip.mp4');
  late DemoStore store;
  late _RecordingLibraryRepository repository;
  late FakeMediaUploader uploader;

  setUp(() {
    store = DemoStore.seed(now: () => now);
    repository = _RecordingLibraryRepository(DemoLibraryRepository(store));
    uploader = FakeMediaUploader();
  });

  blocTest<UploadCubit, UploadState>(
    'real path: uploader progress drives the states, then the video lands',
    build: () => UploadCubit(repository, uploader: uploader),
    act: (cubit) => cubit.start(
      title: 'Real clip',
      bodyPart: 'Knee',
      durationSec: 45,
      file: clip,
    ),
    expect: () => [
      isA<UploadCompressing>().having((s) => s.progress, 'progress', 0.5),
      isA<UploadCompressing>().having((s) => s.progress, 'progress', 1.0),
      isA<UploadUploading>().having((s) => s.progress, 'progress', 0.5),
      isA<UploadUploading>().having((s) => s.progress, 'progress', 1.0),
      isA<UploadDone>(),
    ],
    verify: (cubit) {
      final done = cubit.state as UploadDone;
      expect(done.video.title, 'Real clip');
      expect(uploader.lastFile, same(clip));
      expect(store.videos.value.contains(done.video), isTrue);
      expect(repository.lastMedia, same(FakeMediaUploader.result),
          reason: 'the Storage result must reach the video doc');
    },
  );

  blocTest<UploadCubit, UploadState>(
    'real path: a "!" title is NOT a failure trigger outside the demo',
    build: () => UploadCubit(repository, uploader: uploader),
    act: (cubit) => cubit.start(
      title: 'Stretch!',
      bodyPart: 'Neck',
      durationSec: 30,
      file: clip,
    ),
    expect: () => [
      isA<UploadCompressing>(),
      isA<UploadCompressing>(),
      isA<UploadUploading>(),
      isA<UploadUploading>(),
      isA<UploadDone>(),
    ],
  );

  blocTest<UploadCubit, UploadState>(
    'real path: without a picked file nothing runs',
    build: () => UploadCubit(repository, uploader: uploader),
    act: (cubit) => cubit.start(
      title: 'No clip attached',
      bodyPart: 'Knee',
      durationSec: 45,
    ),
    expect: () => [
      isA<UploadFailed>(),
    ],
    verify: (cubit) {
      expect(uploader.uploadCalls, 0);
      expect(store.videos.value.any((v) => v.title == 'No clip attached'),
          isFalse);
    },
  );

  test('real path: upload failure surfaces its message, retry re-runs',
      () async {
    uploader.failure = const MediaUploadException(
        MediaUploadStage.upload, 'Prijenos nije uspio.');
    final cubit = UploadCubit(repository, uploader: uploader);
    addTearDown(cubit.close);

    await cubit.start(
        title: 'Flaky net', bodyPart: 'Knee', durationSec: 45, file: clip);
    expect(cubit.state,
        isA<UploadFailed>().having((s) => s.message, 'message', 'Prijenos nije uspio.'));
    expect(store.videos.value.any((v) => v.title == 'Flaky net'), isFalse);

    // Network back: the retained args + file finish the job.
    uploader.failure = null;
    await cubit.retry();
    expect(cubit.state, isA<UploadDone>());
    expect(uploader.uploadCalls, 2);
    expect(store.videos.value.any((v) => v.title == 'Flaky net'), isTrue);
  });
}
