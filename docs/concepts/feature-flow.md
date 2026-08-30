---
title: Feature flow
description: Understand how ff_bloc connects event-local operations, stream-based state emission, errors, observers, UI rendering, and disposal.
---

# Feature flow

FF Bloc changes where the handler lives, not the core BLoC model. The UI still
adds an event and observes states. The event itself supplies the state stream.

## Runtime sequence

1. The UI or a repository subscription calls `bloc.add(event)`.
2. The configured `FFEventConcurrency` policy schedules or rejects the event.
3. `onObserver` runs when the event handler actually starts.
4. The bloc subscribes to `event.applyAsync(bloc: this)`.
5. Every state from that stream is emitted through the normal BLoC transition.
6. `onTransitionObserver` runs for each transition.
7. An uncaught error is reported to the global `BlocObserver`, passed to
   `onErrorObserver`, and converted through `onErrorState`.
8. Closing the bloc cancels subscriptions returned by `initSubscriptions`
   before closing the underlying BLoC stream.

Dropped events do not reach step 3. Restarted events can begin side effects, but
their cancelled streams no longer emit states into the bloc.

## Suggested feature structure

```text
todos/
├── index.dart
├── todos_bloc.dart
├── todos_event.dart
├── todos_state.dart
├── todos_model.dart
├── todos_provider.dart
├── todos_page.dart
└── todos_screen.dart
```

The structure is intentionally feature-oriented. A repository call and its
loading/success emissions stay in one event file, while the bloc remains the
place for shared policy and dependencies.

## Event responsibility

An event should own one user or system intent:

```dart
class SaveProfileEvent extends ProfileEvent {
  SaveProfileEvent(this.draft);

  final ProfileDraft draft;

  @override
  Stream<ProfileState> applyAsync({required ProfileBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    final profile = await bloc.repository.save(draft);
    yield bloc.state.copyWithoutError(
      isLoading: false,
      data: profile,
    );
  }
}
```

Keep validation that belongs exclusively to this operation nearby. Keep shared
business rules in the domain or service layer rather than duplicating them in
events.

## Bloc responsibility

The bloc owns concerns shared across its events:

- injected repositories and services;
- initial state;
- one event concurrency policy;
- error-to-state conversion;
- logging and transition hooks;
- long-lived subscriptions;
- disposal.

If two event families require incompatible overlap policies, separate them into
different blocs or deliberately override `transform`. The constructor policy
applies to the single base event handler and therefore every event subtype.

## UI responsibility

Widgets dispatch intents and render state. They should not duplicate event
ordering, error conversion, or repository lifecycle:

```dart
context.read<ProfileBloc>().add(SaveProfileEvent(draft));
```

Use regular `BlocBuilder`, `BlocListener`, `BlocConsumer`, and selectors. FF Bloc
does not wrap or replace the widget layer.

## Application-specific base classes

Large applications may wrap FF Bloc behind `AppBloc`, `AppState`, or a feature
DI boundary. Preserve the flow rather than leaking service-location concerns
into every event:

```text
intent → event → bloc → repository/service → explicit state → UI
```

Keep wrappers small, retain the FF Bloc observer and disposal contracts, and
cover any changed behavior with regression tests.
