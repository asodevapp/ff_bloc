---
title: Get started
description: Install ff_bloc and build a complete event, state, bloc, provider, and Flutter view with explicit error and lifecycle ownership.
---

# Get started

This guide builds one loadable todo feature. Replace the sample repository with
your own service or domain layer; FF Bloc does not prescribe data access.

## 1. Install the packages

```shell
flutter pub add ff_bloc flutter_bloc
```

Import `ff_bloc` in state, event, and bloc files. Import `flutter_bloc` directly
in widgets so the application declares the package it uses.

## 2. Define the state

```dart
import 'package:ff_bloc/ff_bloc.dart';

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

Override `isEmpty` because a non-null empty list is still an empty UI result.
Without the override, any non-null list has data status.

## 3. Define events

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

class ClearTodosEvent extends TodosEvent {
  @override
  Stream<TodosState> applyAsync({required TodosBloc bloc}) async* {
    yield bloc.state.copyClear();
  }
}
```

An event may emit zero, one, or several states. Let an unexpected error escape;
the bloc converts it through `onErrorState` and preserves its stack trace for
observers.

## 4. Create the bloc

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

Sequential processing is the default. Keep it for ordered workflows. Change it
only when the feature has a clear latest-result, duplicate-submit, or independent
read contract.

## 5. Provide and start the bloc

```dart
BlocProvider(
  create: (_) => TodosBloc(repository: repository)..add(LoadTodosEvent()),
  child: const TodosView(),
)
```

`BlocProvider(create: ...)` owns and closes the bloc. Do not also register the
same instance as a GetIt-owned singleton.

## 6. Render the state

```dart
class TodosView extends StatelessWidget {
  const TodosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosBloc, TodosState>(
      builder: (context, state) {
        return state.when(
          onLoading: () => const CircularProgressIndicator(),
          onEmpty: (_) => const Text('No todos'),
          onData: (todos) => ListView(
            children: [
              for (final todo in todos) ListTile(title: Text(todo)),
            ],
          ),
          onError: (error) => Column(
            children: [
              Text('Could not load todos: $error'),
              TextButton(
                onPressed: () =>
                    context.read<TodosBloc>().add(LoadTodosEvent()),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

## 7. Test the contract

At minimum, verify:

- initial empty state;
- loading then data for success;
- error conversion clears loading;
- empty domain data uses the empty branch;
- selected concurrency behavior;
- owned subscriptions are cancelled on close.

See [Testing](guides/testing.md) for deterministic event and lifecycle patterns.

## Next steps

- Learn the exact [state precedence and copy semantics](concepts/state-model.md).
- Select [event concurrency](concepts/event-concurrency.md).
- Add [logging without losing the original error](guides/errors-and-observers.md).
- Choose [GetIt, BlocProvider, or explicit ownership](guides/subscriptions-and-disposal.md).
