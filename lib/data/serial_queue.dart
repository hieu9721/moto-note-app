// lib/data/serial_queue.dart — the ordering-and-failure primitives the
// mutation funnel needs (§12: a new file per tiny function is what §12
// forbids, so both live here).
//
// SerialQueue is the mechanism both AppNotifier._mutate and
// AppDataRepository.save() need: chain every queued task onto the previous
// one so only one is ever in flight, while a failed task never poisons the
// tasks issued after it. It is deliberately PURE DART — no
// package:flutter/... import — so DATA-03's ordering property is testable
// under plain `dart test` without a fourth test file (D-32 / P1-D-11).
// Extracted per gap G-01-5. This does NOT mean AppDataRepository.save() has
// been migrated onto it — it has not, by design (see 01-06-PLAN.md's
// explicit non-goals).
class SerialQueue {
  Future<void> _last = Future.value();

  /// Enqueues [task], chaining it onto every task enqueued before it.
  ///
  /// The future returned to the caller propagates [task]'s own failure
  /// normally. The future stored back into [_last] is a DIFFERENT object
  /// that swallows the error via `catchError` — that is precisely why one
  /// failed task cannot poison every task issued after it. [_last] is
  /// reassigned synchronously, before any `await`, so two calls made in the
  /// same synchronous block chain in call order.
  Future<void> enqueue(Future<void> Function() task) {
    final resultFuture = _last.then((_) => task());
    _last = resultFuture.catchError((_) {});
    return resultFuture;
  }
}

/// The post-persist failure boundary (G-01-W3 / WR-03): runs [effect], an
/// operation whose failure must be REPORTED rather than PROPAGATED, so a
/// side effect that runs after an operation has already committed can never
/// masquerade as a failure of that operation. [effect] is awaited inside a
/// `try`, so both an asynchronous throw (after [effect]'s first `await`) and
/// a synchronous throw (before [effect] returns any future at all) are
/// caught the same way. Kept pure Dart — no Flutter import, no logging
/// framework, no `print` — the caller decides how to report [onError].
Future<void> runReportingFailure(
  Future<void> Function() effect, {
  required void Function(Object error) onError,
}) async {
  try {
    await effect();
  } catch (e) {
    onError(e);
  }
}
