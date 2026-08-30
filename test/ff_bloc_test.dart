import 'dart:async';

import 'package:ff_bloc/ff_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FFState', () {
    test('derives status with loading, error, empty, data priority', () {
      expect(const _TestState().status, FFStateStatus.empty);
      expect(const _TestState(data: 1).status, FFStateStatus.data);
      expect(
        _TestState(error: StateError('failed')).status,
        FFStateStatus.error,
      );
      expect(
        _TestState(
          isLoading: true,
          data: 1,
          error: StateError('stale'),
        ).status,
        FFStateStatus.loading,
      );
    });

    test('when and whenOrElse map the derived status', () {
      const state = _TestState(data: 7);

      expect(
        state.when(
          onLoading: () => 'loading',
          onError: (_) => 'error',
          onEmpty: (_) => 'empty',
          onData: (data) => 'data:$data',
        ),
        'data:7',
      );
      expect(
        state.whenOrElse(
          onError: (_) => 'error',
          onElse: () => 'fallback',
        ),
        'fallback',
      );
    });

    test('copy helpers preserve and clear the documented fields', () {
      final error = StateError('failed');
      final state = _TestState(
        version: 4,
        isLoading: true,
        data: 7,
        error: error,
      );

      final copied = state.copy(data: null, error: null);
      expect(copied.version, 5);
      expect(copied.data, 7);
      expect(copied.error, same(error));
      expect(copied.isLoading, isTrue);

      final withoutError = state.copyWithoutError(isLoading: false);
      expect(withoutError.version, 5);
      expect(withoutError.data, 7);
      expect(withoutError.error, isNull);
      expect(withoutError.isLoading, isFalse);

      final withoutData = state.copyWithoutData(isLoading: false);
      expect(withoutData.version, 5);
      expect(withoutData.data, isNull);
      expect(withoutData.error, same(error));

      final cleared = state.copyClear();
      expect(cleared.version, 5);
      expect(cleared.data, isNull);
      expect(cleared.error, isNull);
      expect(cleared.isLoading, isFalse);
    });
  });

  group('FFEventConcurrency', () {
    test('sequential is the default and preserves event order', () async {
      final bloc = _TestBloc();
      final first = _ControlledEvent(1);
      final second = _ControlledEvent(2);
      addTearDown(() async {
        await bloc.close();
        await first.dispose();
        await second.dispose();
      });

      expect(bloc.eventConcurrency, FFEventConcurrency.sequential);

      bloc.add(first);
      await first.started.future;
      bloc.add(second);
      await _flushEvents();
      expect(second.started.isCompleted, isFalse);

      final firstState = bloc.stream.firstWhere((state) => state.data == 1);
      first.emit();
      expect((await firstState).data, 1);
      await first.finish();
      await second.started.future;

      final secondState = bloc.stream.firstWhere((state) => state.data == 2);
      second.emit();
      expect((await secondState).data, 2);
      await second.finish();
    });

    test('concurrent emits states in completion order', () async {
      final bloc = _TestBloc(
        eventConcurrency: FFEventConcurrency.concurrent,
      );
      final first = _ControlledEvent(1);
      final second = _ControlledEvent(2);
      addTearDown(() async {
        await bloc.close();
        await first.dispose();
        await second.dispose();
      });

      bloc
        ..add(first)
        ..add(second);
      await Future.wait([first.started.future, second.started.future]);

      final secondState = bloc.stream.firstWhere((state) => state.data == 2);
      second.emit();
      expect((await secondState).data, 2);

      final firstState = bloc.stream.firstWhere((state) => state.data == 1);
      first.emit();
      expect((await firstState).data, 1);
      await Future.wait([first.finish(), second.finish()]);
    });

    test('droppable ignores events added while another event is active',
        () async {
      final bloc = _TestBloc(
        eventConcurrency: FFEventConcurrency.droppable,
      );
      final first = _ControlledEvent(1);
      final dropped = _ControlledEvent(2);
      addTearDown(() async {
        await bloc.close();
        await first.dispose();
        await dropped.dispose();
      });

      bloc.add(first);
      await first.started.future;
      bloc.add(dropped);
      await _flushEvents();

      expect(dropped.started.isCompleted, isFalse);
      final firstState = bloc.stream.firstWhere((state) => state.data == 1);
      first.emit();
      expect((await firstState).data, 1);
      await first.finish();
      await _flushEvents();
      expect(dropped.started.isCompleted, isFalse);
    });

    test('restartable cancels the old handler and uses the newest event',
        () async {
      final bloc = _TestBloc(
        eventConcurrency: FFEventConcurrency.restartable,
      );
      final first = _ControlledEvent(1);
      final second = _ControlledEvent(2);
      addTearDown(() async {
        await bloc.close();
        await first.dispose();
        await second.dispose();
      });

      bloc.add(first);
      await first.started.future;
      bloc.add(second);
      await second.started.future;
      expect(first.cancelled.isCompleted, isTrue);

      first.emit();
      await _flushEvents();
      expect(bloc.state.data, isNull);

      final secondState = bloc.stream.firstWhere((state) => state.data == 2);
      second.emit();
      expect((await secondState).data, 2);
      await second.finish();
    });
  });

  test('event errors reach observers and become an error state', () async {
    final previousObserver = Bloc.observer;
    final observer = _RecordingObserver();
    Bloc.observer = observer;
    final bloc = _TestBloc();
    addTearDown(() async {
      Bloc.observer = previousObserver;
      await bloc.close();
    });

    final stateFuture = bloc.stream.firstWhere((state) => state.hasError);
    bloc.add(_FailingEvent());
    final state = await stateFuture;

    expect(state.isLoading, isFalse);
    expect(state.error, isA<StateError>());
    expect(observer.errors, hasLength(1));
    expect(bloc.observedErrors, hasLength(1));
  });

  test('FFGenericBloc errors also reach the global observer', () async {
    final previousObserver = Bloc.observer;
    final observer = _RecordingObserver();
    Bloc.observer = observer;
    final bloc = _GenericBloc();
    addTearDown(() async {
      Bloc.observer = previousObserver;
      await bloc.close();
    });

    final stateFuture = bloc.stream.firstWhere((state) => state.hasError);
    bloc.add(_GenericFailingEvent());
    final state = await stateFuture;

    expect(state.error, isA<StateError>());
    expect(observer.errors, hasLength(1));
  });

  test('onDispose closes the bloc and its owned subscriptions', () async {
    final source = StreamController<int>.broadcast();
    final bloc = _TestBloc(subscriptionSource: source.stream);
    addTearDown(source.close);

    expect(source.hasListener, isTrue);
    await bloc.onDispose();

    expect(bloc.isClosed, isTrue);
    expect(source.hasListener, isFalse);
  });
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

class _TestState extends FFState<_TestState, int> {
  const _TestState({
    super.version = 0,
    super.isLoading = false,
    super.data,
    super.error,
  });

  @override
  StateCopyFactory<_TestState, int> getCopyFactory() => _TestState.new;
}

abstract class _TestEvent implements FFBlocEvent<_TestState, _TestBloc> {}

class _ControlledEvent extends _TestEvent {
  _ControlledEvent(this.value) {
    _controller = StreamController<int>.broadcast(
      onListen: started.complete,
      onCancel: () {
        if (!cancelled.isCompleted) {
          cancelled.complete();
        }
      },
    );
  }

  final int value;
  final Completer<void> started = Completer<void>();
  final Completer<void> cancelled = Completer<void>();
  late final StreamController<int> _controller;

  void emit() => _controller.add(value);

  Future<void> finish() => _controller.close();

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  Stream<_TestState> applyAsync({required _TestBloc bloc}) {
    return _controller.stream.map(
      (value) => bloc.state.copyWithoutError(
        isLoading: false,
        data: value,
      ),
    );
  }
}

class _FailingEvent extends _TestEvent {
  @override
  Stream<_TestState> applyAsync({required _TestBloc bloc}) async* {
    throw StateError('failed event');
  }
}

class _TestBloc extends FFBloc<_TestEvent, _TestState> {
  _TestBloc({
    FFEventConcurrency eventConcurrency = FFEventConcurrency.sequential,
    Stream<int>? subscriptionSource,
  })  : _subscriptionSource = subscriptionSource,
        super(
          initialState: const _TestState(),
          eventConcurrency: eventConcurrency,
        );

  final Stream<int>? _subscriptionSource;
  final List<Object> observedErrors = [];

  @override
  Iterable<StreamSubscription>? initSubscriptions() {
    final source = _subscriptionSource;
    return source == null ? null : [source.listen((_) {})];
  }

  @override
  _TestState onErrorState(Object error) => state.copy(
        isLoading: false,
        error: error,
      );

  @override
  void onErrorObserver({
    required _TestEvent event,
    required Object error,
    required StackTrace stackTrace,
  }) {
    observedErrors.add(error);
  }
}

class _RecordingObserver extends BlocObserver {
  final List<Object> errors = [];

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

class _GenericState extends FFGenericState<int> {
  const _GenericState({
    super.version = 0,
    super.isLoading = false,
    super.data,
    super.error,
  });

  @override
  StateCopyFactory<FFGenericState, int> getCopyFactory() {
    return ({
      required int version,
      required bool isLoading,
      required int? data,
      required Object? error,
    }) =>
        _GenericState(
          version: version,
          isLoading: isLoading,
          data: data,
          error: error,
        );
  }

  @override
  _GenericState copy({
    bool? isLoading,
    int? data,
    Object? error,
  }) {
    return _GenericState(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  _GenericState copyWithoutError({
    bool? isLoading,
    int? data,
  }) {
    return _GenericState(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
    );
  }

  @override
  _GenericState copyWithoutData({
    bool? isLoading,
    Object? error,
  }) {
    return _GenericState(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  _GenericState copyClear({bool isLoading = false}) {
    return _GenericState(
      version: version + 1,
      isLoading: isLoading,
    );
  }
}

abstract class _GenericEvent
    implements FFBlocEvent<_GenericState, _GenericBloc> {}

class _GenericFailingEvent extends _GenericEvent {
  @override
  Stream<_GenericState> applyAsync({required _GenericBloc bloc}) async* {
    throw StateError('failed generic event');
  }
}

class _GenericBloc extends FFGenericBloc<_GenericEvent, _GenericState> {
  _GenericBloc() : super(initialState: const _GenericState());

  @override
  _GenericState onErrorState(Object error) => state.copy(
        isLoading: false,
        error: error,
      );
}
