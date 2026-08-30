# ff_bloc

Small BLoC foundations for event-driven Flutter features.

[![Pub](https://img.shields.io/pub/v/ff_bloc.svg)](https://pub.dev/packages/ff_bloc)

[`ff_bloc` on pub.dev](https://pub.dev/packages/ff_bloc) ·
[Documentation](https://asodevapp.github.io/ff_bloc/) ·
[GitHub](https://github.com/asodevapp/ff_bloc)

`ff_bloc` keeps feature logic close to the event that performs it. Each event
returns a stream of states, while the bloc owns error conversion, event
concurrency, subscriptions, observers, and disposal.

## Why ff_bloc

- Event logic lives in `applyAsync`, which makes a feature easy to navigate and
  extend without one large handler method.
- `FFState` provides one explicit loading/data/error model, exhaustive rendering
  helpers, and predictable copy operations.
- Event scheduling is declarative: sequential, concurrent, droppable, or
  restartable.
- Repository or service subscriptions can be owned and cancelled by the bloc.
- `FFBloc` implements GetIt's `Disposable` contract and works with standard
  `BlocBuilder`, `BlocListener`, and `BlocProvider` widgets.
- Observer hooks keep product logging separate from event behavior.

## Install

```shell
flutter pub add ff_bloc flutter_bloc
```

Import the package and `flutter_bloc` widgets where they are used:

```dart
import 'package:ff_bloc/ff_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
```

## Quick start

Define a state. The self type lets the built-in copy helpers return the concrete
state type:

```dart
class TodosState extends FFState<TodosState, List<String>> {
  const TodosState({
    super.version = 0,
    super.isLoading = false,
    super.data,
    super.error,
  });

  @override
  bool get isEmpty => data?.isEmpty ?? true;

  @override
  StateCopyFactory<TodosState, List<String>> getCopyFactory() =>
      TodosState.new;
}
```

Define the event contract and put each operation in its event:

```dart
abstract class TodosEvent
    implements FFBlocEvent<TodosState, TodosBloc> {}

class LoadTodosEvent extends TodosEvent {
  @override
  Stream<TodosState> applyAsync({required TodosBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    final todos = await bloc.repository.loadTodos();
    yield bloc.state.copyWithoutError(
      isLoading: false,
      data: todos,
    );
  }
}
```

Create the bloc and map uncaught errors to a valid state:

```dart
class TodosBloc extends FFBloc<TodosEvent, TodosState> {
  TodosBloc({required this.repository})
      : super(initialState: const TodosState());

  final TodosRepository repository;

  @override
  TodosState onErrorState(Object error) => state.copy(
        isLoading: false,
        error: error,
      );
}
```

Use the state with the regular `flutter_bloc` widgets:

```dart
BlocBuilder<TodosBloc, TodosState>(
  builder: (context, state) {
    return state.when(
      onLoading: () => const CircularProgressIndicator(),
      onEmpty: (_) => const Text('No todos'),
      onData: (todos) => ListView(
        children: [for (final todo in todos) ListTile(title: Text(todo))],
      ),
      onError: (error) => Text('Could not load todos: $error'),
    );
  },
);
```

The complete runnable app is in [`example`](example).

## State contract

`FFState.status` uses a deliberate priority when several fields are present:

1. `isLoading == true` → `FFStateStatus.loading`
2. `error != null` → `FFStateStatus.error`
3. `isEmpty == true` or `data == null` → `FFStateStatus.empty`
4. otherwise → `FFStateStatus.data`

Loading therefore wins over stale data or an old error. Override `isEmpty` when
your domain has a non-null empty value, such as an empty list.

Use `when` when every state needs a branch. Use `whenOrElse` when only selected
states need special handling.

### Copy helpers

Every helper increments `version`, so `Equatable` observes a new state even when
the data instance is unchanged.

| Helper | Data | Error | Loading |
| --- | --- | --- | --- |
| `copy` | keeps the old value when omitted | keeps the old value when omitted | keeps the old value when omitted |
| `copyWithoutError` | replaces when provided | clears | keeps or replaces |
| `copyWithoutData` | clears | replaces when provided | keeps or replaces |
| `copyClear` | clears | clears | defaults to `false` |

`copy(data: null)` and `copy(error: null)` retain the old value. Use the named
clear helper when `null` is the intended result.

## Event concurrency

Events are sequential by default, preserving the order in which they were
added. Select another policy in the bloc constructor:

```dart
class SearchBloc extends FFBloc<SearchEvent, SearchState> {
  SearchBloc({required this.repository})
      : super(
          initialState: const SearchState(),
          eventConcurrency: FFEventConcurrency.restartable,
        );

  final SearchRepository repository;

  @override
  SearchState onErrorState(Object error) =>
      state.copy(isLoading: false, error: error);
}
```

| Policy | Behavior | Typical use |
| --- | --- | --- |
| `sequential` | Queues every event and handles one at a time | Ordered writes and workflows |
| `concurrent` | Lets handlers overlap; states arrive in completion order | Independent reads |
| `droppable` | Ignores new events while one is active | Submit and refresh buttons |
| `restartable` | Stops listening to the old handler and starts the newest | Search and autocomplete |

The policy applies to every event subtype in the bloc. Split unrelated workflows
into separate blocs or override `transform` when they require different rules.
`restartable` cancels the old handler subscription; it cannot undo an HTTP call,
database write, or other side effect that already started.

## Errors and observers

An uncaught error from `applyAsync` follows this path:

1. `Bloc.observer.onError` receives the original error and stack trace.
2. `onErrorObserver` runs for feature-specific logging.
3. `onErrorState` converts the error to a state emitted by the bloc.

Other optional hooks are `onObserver`, called when an event starts, and
`onTransitionObserver`, called for every transition:

```dart
@override
void onObserver({required TodosEvent event}) {
  logger.info('event: $event');
}

@override
void onErrorObserver({
  required TodosEvent event,
  required Object error,
  required StackTrace stackTrace,
}) {
  logger.error('event failed: $event', error, stackTrace);
}
```

## Subscriptions and disposal

Return long-lived subscriptions from `initSubscriptions`. The bloc cancels them
before closing itself:

```dart
@override
Iterable<StreamSubscription> initSubscriptions() {
  return [
    repository.changes.listen((_) => add(LoadTodosEvent())),
  ];
}
```

`FFBloc` and `FFGenericBloc` implement GetIt's `Disposable`. GetIt calls
`onDispose`, which closes the bloc, when a registered singleton or scope is
disposed. Do not give the same bloc to two owners that both close it; choose
either GetIt, `BlocProvider(create: ...)`, or explicit lifecycle ownership.

## FFGenericBloc

Prefer `FFBloc` with `FFState` for new features. `FFGenericBloc` and
`FFGenericState` remain available when a project needs custom copy methods or a
different concrete state hierarchy. They share the same concurrency,
subscription, observer, error, and disposal behavior.

## Feature generation

The [Flutter Files extension](https://marketplace.visualstudio.com/items?itemName=gornivv.vscode-flutter-files)
can generate the feature-oriented bloc, event, state, model, provider, page, and
screen structure used by the example.

## Codex skill

This repository includes the repo-local
[`$ff-bloc`](https://github.com/asodevapp/ff_bloc/blob/main/.agents/skills/ff-bloc/SKILL.md)
skill for implementing, migrating, reviewing, and debugging FF Bloc features.
It covers state-copy semantics, concurrency selection, error observers,
subscription ownership, tests, templates, and package maintenance. Codex can
discover it automatically while working in this checkout, or it can be invoked
explicitly as `$ff-bloc`.

The complete user guide is published at
[asodevapp.github.io/ff_bloc](https://asodevapp.github.io/ff_bloc/). Build it locally
with:

```shell
python3 -m venv build/docs-venv
build/docs-venv/bin/python -m pip install --requirement requirements-docs.txt
build/docs-venv/bin/python -m mkdocs build --strict
build/docs-venv/bin/python -m mkdocs serve
```

## Development

```shell
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
dart doc --dry-run
python3 -m venv build/docs-venv
build/docs-venv/bin/python -m pip install --requirement requirements-docs.txt
build/docs-venv/bin/python -m mkdocs build --strict

cd example
flutter test
```

Release validation is documented in [`PUBLISHING.md`](PUBLISHING.md).

## License

MIT. See [`LICENSE`](LICENSE).
