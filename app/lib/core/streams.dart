import 'dart:async';

/// Combines the latest values of two streams. Emits only once both sources
/// have produced a value, then re-emits on every update from either source.
/// Cancelling the subscription cancels both sources.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combine,
) =>
    _combine([a, b], (vs) => combine(vs[0] as A, vs[1] as B));

Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combine,
) =>
    _combine([a, b, c], (vs) => combine(vs[0] as A, vs[1] as B, vs[2] as C));

Stream<R> combineLatest4<A, B, C, D, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  R Function(A a, B b, C c, D d) combine,
) =>
    _combine([a, b, c, d], (vs) => combine(vs[0] as A, vs[1] as B, vs[2] as C, vs[3] as D));

Stream<R> _combine<R>(List<Stream<dynamic>> sources, R Function(List<dynamic>) combine) {
  final controller = StreamController<R>();
  final values = List<dynamic>.filled(sources.length, null);
  final hasValue = List<bool>.filled(sources.length, false);
  final subs = <StreamSubscription<dynamic>>[];
  var closed = 0;

  void emitIfReady() {
    if (hasValue.every((h) => h)) controller.add(combine(List.of(values)));
  }

  controller.onListen = () {
    for (var i = 0; i < sources.length; i++) {
      subs.add(sources[i].listen(
        (v) {
          values[i] = v;
          hasValue[i] = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          closed++;
          if (closed == sources.length) controller.close();
        },
      ));
    }
  };
  controller.onCancel = () async {
    for (final s in subs) {
      await s.cancel();
    }
  };
  return controller.stream;
}
