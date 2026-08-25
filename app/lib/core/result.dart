/// Lightweight success/failure wrapper. No exceptions cross layer boundaries.
sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T value) ok, required R Function(String message) err}) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final message) => err(message),
      };

  T? get valueOrNull => switch (this) { Ok(:final value) => value, Err() => null };
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}
