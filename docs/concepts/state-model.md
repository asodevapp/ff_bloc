---
title: State model
description: Use FFState status precedence, exhaustive rendering, versioned equality, domain emptiness, and explicit copy and clear semantics.
---

# State model

`FFState<Self, DataT>` combines four fields:

| Field | Meaning |
| --- | --- |
| `version` | Monotonic copy counter included in equality |
| `isLoading` | An operation currently owns the visible loading surface |
| `data` | Last or current domain value |
| `error` | Last unhandled operation error |

The state can retain data while loading or failing. Rendering is determined by
explicit precedence rather than by requiring every field combination to be
mutually exclusive.

## Status precedence

`status` evaluates in this order:

1. `isLoading` → `FFStateStatus.loading`
2. `error != null` → `FFStateStatus.error`
3. `isEmpty || data == null` → `FFStateStatus.empty`
4. otherwise → `FFStateStatus.data`

Loading wins over retained data and an old error. Error wins over retained data.
This supports refresh and retry states without losing the previous model.

!!! warning "Clear loading in the terminal state"
    If `onErrorState` keeps `isLoading: true`, the loading branch continues to
    win and the error is not visible through `when`.

## Domain emptiness

By default, only `null` is empty. Override `isEmpty` when the domain has another
empty representation:

```dart
@override
bool get isEmpty => data?.items.isEmpty ?? true;
```

This lets a non-null empty view model render through `onEmpty` while a populated
model uses `onData`.

## Exhaustive and focused rendering

Use `when` when the UI must account for every status:

```dart
return state.when(
  onLoading: () => const LoadingView(),
  onError: (error) => ErrorView(error: error),
  onEmpty: (_) => const EmptyView(),
  onData: (data) => DataView(data: data),
);
```

Use `whenOrElse` when one or two statuses need special behavior:

```dart
final canSubmit = state.whenOrElse(
  onLoading: () => false,
  onElse: () => true,
);
```

## Copy semantics

Every helper increments `version`.

| Helper | Data | Error | Loading |
| --- | --- | --- | --- |
| `copy` | Retain unless non-null replacement supplied | Retain unless non-null replacement supplied | Retain unless supplied |
| `copyWithoutError` | Retain or replace | Clear | Retain or replace |
| `copyWithoutData` | Clear | Retain or replace | Retain or replace |
| `copyClear` | Clear | Clear | Set explicitly; defaults to false |

`copy(data: null)` and `copy(error: null)` retain old values because the method
uses nullable optional parameters. Use the named clear helpers when `null` is
the desired result.

Typical transitions:

```dart
// Start a refresh and keep old data.
state.copyWithoutError(isLoading: true);

// Finish successfully and clear an old error.
state.copyWithoutError(isLoading: false, data: result);

// Fail and keep old data available for diagnostics or recovery.
state.copy(isLoading: false, error: error);

// Reset the complete feature.
state.copyClear();
```

## Equality and version

`version`, `isLoading`, `data`, and `error` are all in `Equatable.props`. The
incremented version ensures each helper creates a distinct state even when the
same data instance is retained.

Do not construct a replacement state with a lower or repeated version inside a
custom copy path. Consumers may depend on every operation producing a distinct
transition.

## FFGenericState

Use `FFGenericState<DataT>` only when the application must implement its own
copy methods or concrete hierarchy. New features should normally prefer
`FFState<Self, DataT>` because its clear semantics are shared and tested.
