import 'package:bloc_concurrency/bloc_concurrency.dart' as concurrency;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Defines how an `FFBloc` schedules overlapping events.
///
/// The policy is applied to the single event handler registered by `FFBloc`,
/// so it covers every event subtype handled by that bloc.
enum FFEventConcurrency {
  /// Queues events and handles them one at a time in the order they were added.
  sequential,

  /// Handles events at the same time and emits states as soon as they arrive.
  concurrent,

  /// Ignores new events while an event is already being handled.
  droppable,

  /// Stops listening to the previous handler and starts the newest event.
  ///
  /// Any external asynchronous work already started by the previous event may
  /// still continue, but states emitted by its cancelled handler are ignored.
  restartable;

  /// Creates the `bloc` event transformer represented by this policy.
  EventTransformer<Event> createTransformer<Event>() {
    switch (this) {
      case FFEventConcurrency.sequential:
        return concurrency.sequential<Event>();
      case FFEventConcurrency.concurrent:
        return concurrency.concurrent<Event>();
      case FFEventConcurrency.droppable:
        return concurrency.droppable<Event>();
      case FFEventConcurrency.restartable:
        return concurrency.restartable<Event>();
    }
  }
}
