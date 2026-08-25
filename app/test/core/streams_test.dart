import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/streams.dart';
import 'package:physio_app/core/watchable.dart';

void main() {
  test('combineLatest2 emits once both sources have values, then on every update', () async {
    final a = Watchable<int>(1);
    final b = Watchable<String>('x');
    final seen = <String>[];
    final sub = combineLatest2(a.watch(), b.watch(), (int x, String y) => '$x$y').listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    a.update((_) => 2);
    b.update((_) => 'y');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['1x', '2x', '2y']);
    await sub.cancel();
  });

  test('combineLatest3 waits for the slowest source', () async {
    final a = Watchable<int>(1);
    final b = Watchable<int>(2);
    final late = Watchable<int?>(null);
    final seen = <int>[];
    final sub = combineLatest3(
      a.watch(),
      b.watch(),
      late.watch().where((v) => v != null),
      (int x, int y, int? z) => x + y + z!,
    ).listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
    late.update((_) => 10);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [13]);
    await sub.cancel();
  });

  test('cancelling stops all source subscriptions', () async {
    final a = Watchable<int>(0);
    final b = Watchable<int>(0);
    final seen = <int>[];
    final sub = combineLatest2(a.watch(), b.watch(), (int x, int y) => x + y).listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    a.update((v) => v + 1);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [0]);
  });
}
