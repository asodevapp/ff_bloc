---
title: Troubleshooting
description: Diagnose ff_bloc loading, empty-state, copy, event ordering, cancellation, observer, subscription, and disposal problems from observable symptoms.
---

# Troubleshooting

## The error exists but the UI still shows loading

**Cause:** `onErrorState` retained `isLoading: true`. Loading has higher status
precedence than error.

**Fix:** emit or return a state with `isLoading: false`:

```dart
state.copy(isLoading: false, error: error);
```

## An empty list renders the data branch

**Cause:** the default `isEmpty` checks only `data == null`.

**Fix:** override domain emptiness:

```dart
@override
bool get isEmpty => data?.items.isEmpty ?? true;
```

## `copy(data: null)` did not clear data

**Cause:** nullable parameters in `copy` use `null` to mean retain the old
value.

**Fix:** use `copyWithoutData` or `copyClear`.

## `copy(error: null)` did not clear the error

**Cause:** the same retain semantics apply to error.

**Fix:** use `copyWithoutError` for a successful/loading transition or
`copyClear` for a complete reset.

## A button event never starts

**Cause:** a droppable bloc already has an active event. Dropped events do not
enter `applyAsync` or `onObserver`.

**Fix:** verify that duplicate input truly has no meaning. Use sequential when
every event must run, or disable the button while the current event is active.

## An older request changed state after a newer request

**Cause:** concurrent handlers emit in completion order.

**Fix:** use restartable for latest-result reads, sequential for ordered work,
or add a request-generation guard when the external side effect is not
cancellable.

## A restarted HTTP request still reached the server

**Cause:** restartable cancels the handler stream subscription, not arbitrary
external work.

**Fix:** use a cancellation-aware client, idempotency, request tokens, or stale
result guards. Never assume restartable can roll back a write.

## The same exception is reported twice

**Cause:** both the global `BlocObserver` and `onErrorObserver` send it to the
same telemetry backend.

**Fix:** choose one reporting owner. Keep the other hook for local structured
context if needed.

## A repository stream continues after the page closes

**Cause:** the subscription was not returned from `initSubscriptions`, or the
bloc itself was not closed.

**Fix:** return every owned subscription and verify the selected lifecycle owner
actually disposes the bloc.

## A shared bloc is already closed

**Cause:** the same instance had multiple owners, commonly GetIt plus
`BlocProvider(create: ...)`.

**Fix:** expose borrowed instances with `BlocProvider.value` and let GetIt own
disposal, or create a page-local instance that is not registered elsewhere.

## `initSubscriptions` cannot read a dependency

**Cause:** it runs from the FF Bloc constructor before later setup code.

**Fix:** initialize dependencies through constructor fields or initializer-list
entries before the superclass constructor uses the override.

## A custom transformer behaves differently after an upgrade

**Cause:** the subclass overrides `transform`, so the constructor
`eventConcurrency` value is not authoritative.

**Fix:** keep a focused overlap regression test, or remove the override and use
a standard `FFEventConcurrency` policy.

## Publish dry-run fails only on a working checkout

`flutter pub publish --dry-run` treats modified checked-in files as a warning
and warnings are fatal by default. Run from a clean release commit. During local
development, `--ignore-warnings` can confirm that the dirty checkout is the only
remaining warning; never use it to bypass real package validation problems.
