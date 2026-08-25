import 'package:flutter_test/flutter_test.dart';
import 'package:physio_app/core/watchable.dart';

void main() {
  test('new listener immediately receives current value', () async {
    final w = Watchable<int>(7);
    expect(await w.watch().first, 7);
  });

  test('update notifies existing listeners', () async {
    final w = Watchable<int>(0);
    final seen = <int>[];
    final sub = w.watch().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    w.update((v) => v + 1);
    w.update((v) => v + 1);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [0, 1, 2]);
    await sub.cancel();
  });

  test('listener attached after update gets latest value', () async {
    final w = Watchable<int>(0);
    w.update((_) => 42);
    expect(await w.watch().first, 42);
  });

  test('cancelled listener stops receiving', () async {
    final w = Watchable<int>(0);
    final seen = <int>[];
    final sub = w.watch().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    w.update((v) => v + 1);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [0]);
  });
}
