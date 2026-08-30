import 'dart:async';

import 'package:ff_bloc/src/bloc/ff_event.dart';
import 'package:ff_bloc/src/bloc/ff_event_concurrency.dart';
import 'package:ff_bloc/src/bloc/ff_state.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// An [FFBloc] variant for states that implement their own copy operations.
abstract class FFGenericBloc<
        Event extends FFBlocEvent<State, Bloc<Event, State>>,
        State extends FFGenericState> extends Bloc<Event, State>
    implements Disposable {
  FFGenericBloc({
    required State initialState,
    this.eventConcurrency = FFEventConcurrency.sequential,
  }) : super(initialState) {
    final subscriptions = initSubscriptions()?.toList();
    if (subscriptions != null && subscriptions.isNotEmpty) {
      listeners.addAll(subscriptions);
    }
    initOnEvents();
  }

  /// Scheduling policy used when events overlap.
  final FFEventConcurrency eventConcurrency;

  /// Subscriptions owned by this bloc and cancelled by [close].
  @protected
  @nonVirtual
  final listeners = <StreamSubscription>[];

  @override
  @mustCallSuper
  Future onDispose() async {
    return close();
  }

  @override
  @mustCallSuper
  Future<void> close() async {
    for (final listener in listeners) {
      await listener.cancel();
    }
    return super.close();
  }

  @protected
  void initOnEvents() {
    on<Event>(
      (Event event, Emitter<State> emit) {
        onObserver(event: event);
        return emit.forEach<State>(
          event.applyAsync(bloc: this),
          onData: (state) => state,
          onError: (error, stackTrace) {
            // ignore: invalid_use_of_protected_member
            Bloc.observer.onError(this, error, stackTrace);

            onErrorObserver(error: error, event: event, stackTrace: stackTrace);
            return onErrorState(error);
          },
        );
      },
      transformer: transform,
    );
  }

  @protected
  Iterable<StreamSubscription>? initSubscriptions() {
    return null;
  }

  @protected
  State onErrorState(Object error);

  /// Transforms the event stream using [eventConcurrency].
  ///
  /// Existing subclasses may still override this method for a custom policy.
  @protected
  Stream<Event> transform(
      Stream<Event> events, Stream<Event> Function(Event) mapper) {
    return eventConcurrency.createTransformer<Event>().call(events, mapper);
  }

  @override
  @protected
  @mustCallSuper
  void onTransition(Transition<Event, State> transition) {
    onTransitionObserver(transition: transition);
    super.onTransition(transition);
  }

  /// Called when an event starts being handled.
  void onObserver({required Event event}) {}

  /// Called after an event throws and before [onErrorState] is emitted.
  void onErrorObserver(
      {required Event event,
      required Object error,
      required StackTrace stackTrace}) {}

  /// Called for every state transition.
  void onTransitionObserver({required Transition<Event, State> transition}) {}
}
