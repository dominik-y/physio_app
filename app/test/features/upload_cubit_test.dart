import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/data/demo_repositories.dart';
import 'package:physio_app/features/library/upload_cubit.dart';

void main() {
  final now = DateTime(2026, 8, 25, 9, 30);
  late DemoStore store;
  late DemoLibraryRepository repository;

  setUp(() {
    store = DemoStore.seed(now: () => now);
    repository = DemoLibraryRepository(store);
  });

  blocTest<UploadCubit, UploadState>(
    'happy path: compresses then uploads then adds the video to the library',
    build: () => UploadCubit(repository, stepDelay: Duration.zero),
    act: (cubit) => cubit.start(
      title: 'Seated quad extension',
      bodyPart: 'Knee',
      durationSec: 90,
    ),
    expect: () => [
      for (var i = 1; i <= 12; i++)
        isA<UploadCompressing>().having((s) => s.progress, 'progress', closeTo(i / 12, 1e-9)),
      for (var i = 1; i <= 8; i++)
        isA<UploadUploading>().having((s) => s.progress, 'progress', closeTo(i / 8, 1e-9)),
      isA<UploadDone>(),
    ],
    verify: (cubit) {
      final done = cubit.state as UploadDone;
      expect(done.video.title, 'Seated quad extension');
      expect(done.video.bodyPart, 'Knee');
      expect(store.videos.value.contains(done.video), isTrue);
    },
  );

  blocTest<UploadCubit, UploadState>(
    'demo trigger: a title ending in "!" fails partway through upload',
    build: () => UploadCubit(repository, stepDelay: Duration.zero),
    act: (cubit) => cubit.start(
      title: 'Bad!',
      bodyPart: 'Knee',
      durationSec: 60,
    ),
    expect: () => [
      for (var i = 1; i <= 12; i++) isA<UploadCompressing>(),
      for (var i = 1; i <= 4; i++) isA<UploadUploading>(),
      isA<UploadFailed>()
          .having((s) => s.message, 'message', 'Upload failed — connection dropped'),
    ],
    verify: (cubit) {
      expect(store.videos.value.any((v) => v.title == 'Bad!'), isFalse);
    },
  );

  test(
    'retry() re-runs with the same stored args (and so fails again); '
    'a fresh start() with a clean title succeeds',
    () async {
      final cubit = UploadCubit(repository, stepDelay: Duration.zero);
      final states = <UploadState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(() async {
        await sub.cancel();
        await cubit.close();
      });

      await cubit.start(title: 'Bad!', bodyPart: 'Knee', durationSec: 60);
      // The cubit's internal state controller delivers to stream listeners
      // one microtask after `emit` returns, so flush before inspecting
      // [states] (`cubit.state` itself is already synchronously current).
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<UploadFailed>());

      await cubit.retry();
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state,
        isA<UploadFailed>(),
        reason: 'retry() reuses the same stored (still-failing) title',
      );
      expect(
        states.whereType<UploadFailed>().length,
        2,
        reason: 'both the initial attempt and the retry must have failed',
      );

      await cubit.start(title: 'Good demo clip', bodyPart: 'Knee', durationSec: 60);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<UploadDone>());
      final done = cubit.state as UploadDone;
      expect(done.video.title, 'Good demo clip');

      expect(store.videos.value.any((v) => v.title == 'Bad!'), isFalse);
      expect(store.videos.value.any((v) => v.title == 'Good demo clip'), isTrue);
    },
  );
}
