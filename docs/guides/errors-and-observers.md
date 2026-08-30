---
title: Errors and observers
description: Convert ff_bloc event errors to visible states while preserving the original stack trace for global and feature-specific observers.
---

# Errors and observers

Let an unexpected error escape `applyAsync`. FF Bloc keeps error conversion and
reporting consistent across events.

## Error path

An uncaught event-stream error follows this order:

1. `Bloc.observer.onError` receives the bloc, original error, and stack trace.
2. `onErrorObserver` receives the event, error, and stack trace.
3. `onErrorState` converts the error into the next state.

Both `FFBloc` and `FFGenericBloc` use this path.

## Produce a visible error state

```dart
@override
ProfileState onErrorState(Object error) => state.copy(
      isLoading: false,
      error: error,
    );
```

Clear loading because status precedence puts loading before error. `copy` keeps
existing data, which is useful when the UI wants to show a retry surface over a
previous model.

Use `copyWithoutData(isLoading: false, error: error)` when a failure makes old
data invalid.

## Add feature context

```dart
@override
void onObserver({required ProfileEvent event}) {
  logger.info('profile event: $event');
}

@override
void onErrorObserver({
  required ProfileEvent event,
  required Object error,
  required StackTrace stackTrace,
}) {
  logger.error(
    'profile event failed: $event',
    error: error,
    stackTrace: stackTrace,
  );
}
```

`onObserver` runs only when the event begins handling. A droppable event that is
rejected while another event is active does not reach the hook.

## Avoid duplicate reporting

The global and feature-specific hooks both see the same error. Decide which
layer sends telemetry:

- use the global observer for uniform crash/error reporting;
- use the feature hook for structured local logs or context;
- do not send the same exception to the same backend from both layers.

The error is already reported to `Bloc.observer`; do not throw again from
`onErrorState` merely to reach global telemetry.

## Preserve the original error

`onErrorState` receives the original object. Store or map it deliberately:

```dart
@override
ProfileState onErrorState(Object error) {
  final visibleError = error is ProfileNotFound
      ? const ProfileMessage.notFound()
      : ProfileMessage.unexpected(error);
  return state.copy(isLoading: false, error: visibleError);
}
```

Observers still receive the original error and stack trace before mapping.

## Transition observation

Use `onTransitionObserver` for state-change diagnostics:

```dart
@override
void onTransitionObserver({
  required Transition<ProfileEvent, ProfileState> transition,
}) {
  logger.debug('profile transition: $transition');
}
```

Keep observer hooks side-effect-light. A slow logger delays event processing and
can change perceived concurrency.
