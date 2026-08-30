---
title: Event concurrency
description: Choose sequential, concurrent, droppable, or restartable ff_bloc event handling from operation semantics and understand cancellation limits.
---

# Event concurrency

Every FF Bloc registers one handler for its base event type. The
`FFEventConcurrency` value determines how that handler schedules overlapping
events.

## Policies

| Policy | New event while active | State order | Typical use |
| --- | --- | --- | --- |
| `sequential` | Queued | Event order | Writes, imports, multi-step workflows |
| `concurrent` | Starts immediately | Completion order | Independent reads |
| `droppable` | Ignored | Current event only | Submit, refresh, expensive duplicate action |
| `restartable` | Replaces active handler | Latest subscribed handler | Search, autocomplete, selection-driven load |

Sequential is the default and preserves the package's existing behavior.

## Configure the bloc

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

The same constructor parameter is available on `FFGenericBloc`.

## Choose from semantics

=== "Sequential"

    Use when every event must happen and order changes the result. A second
    save should not overtake the first save.

=== "Concurrent"

    Use when operations are independent and completion order is acceptable.
    A slower earlier event may emit after a faster later event.

=== "Droppable"

    Use when repeated input during an active operation has no additional
    meaning. A dropped event never enters `applyAsync` or `onObserver`.

=== "Restartable"

    Use when only the newest result remains relevant. The prior event stream is
    cancelled before the new stream becomes authoritative.

## Cancellation boundary

Restartable cancels the stream subscription used by the event handler. It does
not automatically cancel work owned by an external API:

- an HTTP request may still reach the server;
- a database write may still commit;
- a service future may still complete;
- logging or analytics already emitted remain emitted.

Use cancellation-aware repositories, request tokens, generation checks, or
idempotency where the side effect itself must be bounded. Do not use restartable
for irreversible writes merely to make the UI feel responsive.

## One policy per bloc

Because FF Bloc registers one handler for the base event type, the constructor
policy applies to every event subtype. When search should be restartable but
save must be sequential, prefer separate focused blocs.

Existing subclasses may override `transform` for a deliberate custom rule:

```dart
@override
Stream<SearchEvent> transform(
  Stream<SearchEvent> events,
  Stream<SearchEvent> Function(SearchEvent) mapper,
) {
  return FFEventConcurrency.restartable
      .createTransformer<SearchEvent>()
      .call(events, mapper);
}
```

Keep a regression test for a custom transformer. The constructor policy is
clearer when a standard behavior is sufficient.

## Test overlap explicitly

Use controlled streams or completers instead of real delays:

1. Start the first event and wait until its operation begins.
2. Add the second event before finishing the first.
3. Assert whether the second starts, queues, or is dropped.
4. Complete operations in a deliberate order.
5. Assert the final state and any cancellation signal.

The package test suite covers all four policies with controlled event streams.
