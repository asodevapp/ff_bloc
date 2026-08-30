---
title: Subscriptions and disposal
description: Give ff_bloc repository streams, BlocProvider, GetIt, and explicit injection one clear lifecycle owner and verify cancellation.
---

# Subscriptions and disposal

FF Bloc can own repository or service subscriptions in addition to its event
stream. Every bloc instance must still have exactly one lifecycle owner.

## Register owned subscriptions

```dart
class SessionBloc extends FFBloc<SessionEvent, SessionState> {
  SessionBloc({required this.repository})
      : super(initialState: const SessionState());

  final SessionRepository repository;

  @override
  Iterable<StreamSubscription> initSubscriptions() {
    return [
      repository.changes.listen(
        (session) => add(SessionChangedEvent(session)),
      ),
    ];
  }

  @override
  SessionState onErrorState(Object error) =>
      state.copy(isLoading: false, error: error);
}
```

The constructor snapshots the returned iterable. `close` cancels every owned
subscription before closing the underlying BLoC.

!!! note "Constructor timing"
    `initSubscriptions` runs from the FF Bloc constructor. Dependencies it reads
    must already be initialized through constructor parameters or initializer
    entries. Do not depend on later setup work.

## Choose one owner

=== "BlocProvider"

    ```dart
    BlocProvider(
      create: (_) => SessionBloc(repository: repository),
      child: const SessionView(),
    )
    ```

    `BlocProvider(create: ...)` closes the created bloc.

=== "GetIt"

    ```dart
    getIt.registerLazySingleton<SessionBloc>(
      () => SessionBloc(repository: getIt()),
    );
    ```

    `FFBloc` implements GetIt's `Disposable`. Unregistering, resetting, or
    disposing its scope calls `onDispose`, which closes the bloc.

=== "Explicit owner"

    ```dart
    final bloc = SessionBloc(repository: repository);
    try {
      await runFeature(bloc);
    } finally {
      await bloc.close();
    }
    ```

    Use explicit ownership in tests, commands, or non-widget runtimes.

## Borrowed instances

`BlocProvider.value` exposes an existing bloc and does not close it:

```dart
BlocProvider.value(
  value: getIt<SessionBloc>(),
  child: const SessionView(),
)
```

This is appropriate when GetIt or another parent owns the instance. Do not use
`BlocProvider(create: (_) => getIt<SessionBloc>())`; that makes the provider
look like an owner of a borrowed singleton.

## Avoid double ownership

Common invalid combinations:

- registering a bloc as a GetIt singleton and returning it from
  `BlocProvider(create: ...)`;
- manually closing a bloc that its provider will close;
- closing a GetIt-owned bloc in a page's `dispose`;
- sharing one instance across scopes with independent cleanup.

Double close can race active handlers or make later consumers read a closed
bloc. Select ownership at construction time and keep it visible in tests.

## Test cancellation

```dart
test('close cancels the repository subscription', () async {
  final source = StreamController<int>.broadcast();
  final bloc = TestBloc(source.stream);

  expect(source.hasListener, isTrue);
  await bloc.close();
  expect(source.hasListener, isFalse);

  await source.close();
});
```

Also test GetIt scope reset when the application relies on automatic
`Disposable` handling rather than explicit `close`.
