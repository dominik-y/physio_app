import 'dart:async';

/// A reactive in-memory value: every new listener immediately receives the
/// current value, and every [update] notifies all listeners. Backs the demo
/// repositories so open screens react to mutations live.
class Watchable<T> {
  T _value;
  final List<MultiStreamController<T>> _controllers = [];

  Watchable(this._value);

  T get value => _value;

  Stream<T> watch() => Stream.multi((controller) {
        controller.add(_value);
        _controllers.add(controller);
        controller.onCancel = () => _controllers.remove(controller);
      });

  void update(T Function(T current) fn) {
    _value = fn(_value);
    for (final c in List.of(_controllers)) {
      c.add(_value);
    }
  }
}
