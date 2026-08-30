---
title: Event-driven Flutter state with FF Bloc
description: Build traceable Flutter features with stream-based events, explicit loading/data/error states, deliberate concurrency, and owned lifecycle.
---

<div class="ff-hero" markdown>

# State changes you can trace

Keep each operation in its event, derive UI from one explicit state contract,
and choose what overlapping work means instead of inheriting accidental
concurrency.

<div class="ff-actions" markdown>
[Get started](getting-started.md){ .md-button .md-button--primary }
[View on pub.dev](https://pub.dev/packages/ff_bloc){ .md-button }
[View on GitHub](https://github.com/asodevapp/ff_bloc){ .md-button }
</div>

</div>

FF Bloc is a small foundation over `bloc`, `flutter_bloc`, `bloc_concurrency`,
`equatable`, and GetIt. It keeps application-specific repositories, models, and
widgets in your project while standardizing the event-to-state runtime around
them.

<div class="ff-grid" markdown>

<div class="ff-card" markdown>
### Event-local operations

Every event implements `applyAsync` and emits its own state stream. A feature is
read by following one event instead of searching a central handler.
</div>

<div class="ff-card" markdown>
### Explicit UI state

`FFState` derives loading, error, empty, or data status and provides exhaustive
`when` plus focused `whenOrElse` rendering.
</div>

<div class="ff-card" markdown>
### Deliberate concurrency

Select sequential, concurrent, droppable, or restartable behavior in the bloc
constructor. Sequential remains the compatible default.
</div>

<div class="ff-card" markdown>
### Owned lifecycle

The bloc cancels repository subscriptions before closing and implements GetIt's
`Disposable` contract without replacing standard `BlocProvider` ownership.
</div>

</div>

## Five-minute example

Install the runtime package and the Flutter widgets used by the application:

```shell
flutter pub add ff_bloc flutter_bloc
```

Keep the operation in the event:

```dart
class LoadProfileEvent extends ProfileEvent {
  @override
  Stream<ProfileState> applyAsync({required ProfileBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    final profile = await bloc.repository.loadProfile();
    yield bloc.state.copyWithoutError(
      isLoading: false,
      data: profile,
    );
  }
}
```

Choose the overlap policy at the bloc boundary:

```dart
class ProfileBloc extends FFBloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.repository})
      : super(
          initialState: const ProfileState(),
          eventConcurrency: FFEventConcurrency.restartable,
        );

  final ProfileRepository repository;

  @override
  ProfileState onErrorState(Object error) =>
      state.copy(isLoading: false, error: error);
}
```

!!! note "Use restartable only for latest-result workflows"
    Restartable stops listening to the previous event stream. It cannot undo an
    HTTP request, database write, or other side effect that already started.

## One feature, two responsibilities

<div class="ff-boundary" markdown>
<div markdown>
**The event owns the operation**

Input, repository call, intermediate loading state, and successful state
emissions stay together in `applyAsync`.
</div>
<div markdown>
**The bloc owns runtime policy**

Initial state, concurrency, error conversion, observers, long-lived
subscriptions, and disposal stay at the feature boundary.
</div>
</div>

The UI remains regular `flutter_bloc`: provide the bloc, dispatch events, and
render the derived state.

## Choose your next step

- Follow [Get started](getting-started.md) for a complete feature.
- Understand the [feature flow](concepts/feature-flow.md) before introducing an
  application-specific base bloc.
- Choose an [event concurrency policy](concepts/event-concurrency.md) from the
  operation's semantics, not its perceived speed.
- Define one [lifecycle owner](guides/subscriptions-and-disposal.md) for every
  bloc.
- Use the repo-local [Codex skill](guides/codex-skill.md) for implementation,
  review, migration, and debugging tasks.

## Requirements

- Dart 2.18.4 or newer
- Flutter 3.3 or newer
- `flutter_bloc` 8 or 9

FF Bloc is available under the MIT License.
