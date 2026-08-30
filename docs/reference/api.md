---
title: API reference
description: Public ff_bloc classes, fields, status and copy helpers, event concurrency, observers, subscriptions, and generic-state compatibility APIs.
---

# API reference

Import the public library:

```dart
import 'package:ff_bloc/ff_bloc.dart';
```

## FFBloc

```dart
abstract class FFBloc<
  Event extends FFBlocEvent<State, Bloc<Event, State>>,
  State extends FFState,
> extends Bloc<Event, State> implements Disposable
```

Constructor:

```dart
FFBloc({
  required State initialState,
  FFEventConcurrency eventConcurrency = FFEventConcurrency.sequential,
})
```

Members:

| Member | Contract |
| --- | --- |
| `eventConcurrency` | Shared scheduling policy for the base event handler |
| `listeners` | Protected owned subscriptions cancelled by `close` |
| `initSubscriptions()` | Override to return long-lived owned subscriptions |
| `onErrorState(error)` | Required error-to-state conversion |
| `transform(events, mapper)` | Protected extension point; defaults to the configured policy |
| `onObserver(event:)` | Called when an event starts handling |
| `onErrorObserver(...)` | Called with event, error, and stack trace before error-state emission |
| `onTransitionObserver(...)` | Called for every BLoC transition |
| `onDispose()` | GetIt `Disposable` entry point; closes the bloc |
| `close()` | Cancels owned subscriptions, then closes BLoC |

## FFGenericBloc

`FFGenericBloc<Event, State extends FFGenericState>` provides the same
concurrency, subscriptions, observers, error flow, and disposal contract for a
state hierarchy that implements its own copy operations.

Prefer `FFBloc` for new features unless custom state inheritance is required.

## FFBlocEvent

```dart
abstract class FFBlocEvent<State, B extends Bloc> {
  Stream<State> applyAsync({required B bloc});
}
```

Implement the interface from an application event base class. `applyAsync` may
emit zero or more states and may complete synchronously or asynchronously.
Uncaught stream errors enter the bloc error path.

## FFEventConcurrency

Values:

- `sequential`
- `concurrent`
- `droppable`
- `restartable`

`createTransformer<Event>()` exposes the underlying typed BLoC transformer for
custom `transform` overrides.

## FFState

```dart
abstract class FFState<Self, DataT> extends Equatable
```

Constructor fields:

```dart
const FFState({
  required int version,
  required bool isLoading,
  required DataT? data,
  required Object? error,
})
```

Although the current `error` field is dynamically typed for compatibility,
error callbacks receive it as `Object` after a non-null check.

Derived members:

| Member | Meaning |
| --- | --- |
| `status` | Loading, error, empty, or data using documented precedence |
| `hasError` | `error != null` |
| `hasData` | `data != null` |
| `hasNoData` | Negation of `hasData` |
| `isEmpty` | Defaults to `data == null`; may be overridden |
| `isNotEmpty` | Negation of `isEmpty` |

Pattern helpers:

```dart
R when<R>({
  required R Function() onLoading,
  required R Function(Object error) onError,
  required R Function(DataT? data) onEmpty,
  required R Function(DataT data) onData,
})
```

```dart
R whenOrElse<R>({
  required R Function() onElse,
  R Function()? onLoading,
  R Function(Object error)? onError,
  R Function(DataT? data)? onEmpty,
  R Function(DataT data)? onData,
})
```

Copy helpers:

```dart
Self copy({bool? isLoading, DataT? data, Object? error});
Self copyWithoutError({bool? isLoading, DataT? data});
Self copyWithoutData({bool? isLoading, Object? error});
Self copyClear({bool isLoading = false});
```

Subclasses implement:

```dart
StateCopyFactory<Self, DataT> getCopyFactory();
```

The factory receives required `version`, `isLoading`, `data`, and `error`
arguments. Every built-in helper passes `version + 1`.

## FFStateStatus

Values:

- `empty`
- `loading`
- `data`
- `error`

The `StatusCheck` extension provides `isEmpty`, `isLoading`, `isData`, and
`isError` boolean getters.

## FFGenericState

`FFGenericState<DataT>` exposes the same fields, status derivation, pattern
helpers, and equality contract but requires concrete subclasses to implement
the copy methods. It remains available for application-specific state
hierarchies and compatibility.

## Re-export boundary

`package:ff_bloc/ff_bloc.dart` exports only FF Bloc public APIs. It does not
re-export `flutter_bloc`, so applications using `BlocBuilder`, `BlocProvider`,
or BLoC types directly should declare and import `flutter_bloc` themselves.
