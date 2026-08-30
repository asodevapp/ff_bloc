---
title: Testing
description: Test ff_bloc state helpers, event streams, overlap policies, error observers, subscriptions, and Flutter rendering deterministically.
---

# Testing

Test the contract at the narrowest layer that owns it. FF Bloc events are plain
state streams, so most behavior does not require a full widget tree.

## State tests

Cover status precedence and domain emptiness directly:

```dart
test('loading wins over retained data and error', () {
  final state = ProfileState(
    isLoading: true,
    data: profile,
    error: StateError('stale'),
  );

  expect(state.status, FFStateStatus.loading);
});
```

For every custom `isEmpty`, test null, empty, and populated data.

## Event tests

Use a fake repository and observe the bloc stream:

```dart
test('load emits loading then data', () async {
  final bloc = ProfileBloc(repository: FakeProfileRepository(profile));
  addTearDown(bloc.close);

  expectLater(
    bloc.stream,
    emitsInOrder([
      isA<ProfileState>().having((state) => state.isLoading, 'loading', true),
      isA<ProfileState>().having((state) => state.data, 'data', profile),
    ]),
  );

  bloc.add(LoadProfileEvent());
});
```

Await the expectation in production tests so the test cannot finish before the
stream contract is observed.

## Concurrency tests

Do not use arbitrary delays to create overlap. Control event completion with a
`Completer` or `StreamController`:

- sequential: second event starts only after the first stream closes;
- concurrent: both start and states follow deliberate completion order;
- droppable: second event never starts while the first is active;
- restartable: first stream is cancelled and its later state is ignored.

Verify the side-effect boundary separately when a repository supports request
cancellation or idempotency.

## Error tests

Assert all three outcomes:

1. the global `BlocObserver` receives the original error;
2. `onErrorObserver` receives the event and stack trace;
3. the emitted state has visible error status and loading is false.

Restore the previous global observer in teardown to keep tests isolated.

## Lifecycle tests

Use a broadcast controller's `hasListener` or a fake subscription with a cancel
counter. Verify close, `onDispose`, and application-specific GetIt scope reset
when each path is used.

## Widget tests

Widget tests should verify integration rather than repeat event internals:

- `BlocProvider` creates and closes the bloc;
- the initial event starts;
- loading, data, empty, and error branches render;
- retry or clear controls dispatch the intended event.

The package example contains a complete interaction test covering load, add,
clear, error, and retry.

## Package verification

Run from the package root:

```shell
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
dart doc --dry-run

cd example
flutter test
```

For release work, also build the documentation strictly in an isolated Python
environment and run the package publish dry-run from a clean checkout:

```shell
python3 -m venv build/docs-venv
build/docs-venv/bin/python -m pip install --requirement requirements-docs.txt
build/docs-venv/bin/python -m mkdocs build --strict
flutter pub publish --dry-run
```
