---
name: ff-bloc
description: Build, migrate, review, debug, or maintain Flutter features based on ff_bloc. Use when working with FFBloc, FFGenericBloc, FFBlocEvent.applyAsync, FFState status or copy helpers, event concurrency, repository subscriptions, GetIt or BlocProvider disposal, observer/error flow, Flutter Files templates, or ff_bloc package documentation and releases.
---

# Work with FF Bloc

Use the checked-out implementation, public exports, tests, and generated docs as
the source of truth. Distinguish package maintenance from consumer-feature work
before editing.

## Trace the Complete Feature

Follow the actual path before changing behavior:

```text
intent → FFBlocEvent.applyAsync → repository/service → emitted FFState → UI
```

Inspect lifecycle and error paths alongside the success path. Keep domain rules
in services or repositories; keep one operation's orchestration and state
emissions in its event; keep shared runtime policy in the bloc.

For a new feature or migration, read
[Feature flow](../../../docs/concepts/feature-flow.md). Preserve an existing
application-specific base bloc or DI boundary unless the user explicitly asks
to replace it.

## Preserve the State Contract

- Keep status precedence as loading, error, empty, then data.
- Clear `isLoading` in terminal success and error states.
- Override `isEmpty` for non-null domain emptiness such as an empty list.
- Use `copyWithoutError` for loading/success, `copyWithoutData` to invalidate
  data, and `copyClear` for a full reset.
- Do not expect `copy(data: null)` or `copy(error: null)` to clear a field.
- Keep copy versions monotonic so Equatable observes each state.

Read [State model](../../../docs/concepts/state-model.md) when changing a state,
copy path, rendering branch, or generic state hierarchy.

## Choose Concurrency from Semantics

Use `FFEventConcurrency.sequential` for ordered work and as the compatible
default. Choose another policy only with an explicit overlap contract:

- `concurrent`: independent work may finish in any order;
- `droppable`: input during active work has no meaning;
- `restartable`: only the newest subscribed result remains relevant.

Treat restartable as stream cancellation, not side-effect cancellation. Add
request cancellation, idempotency, generation guards, or stale-result checks
when external work must be bounded.

The constructor policy applies to every event subtype because FF Bloc registers
one base event handler. Split event families into focused blocs when they need
different policies. Preserve a custom `transform` override with a regression
test.

Read [Event concurrency](../../../docs/concepts/event-concurrency.md) for overlap
changes or ordering bugs.

## Keep Errors Observable

Let unexpected event-stream errors reach the established path:

1. global `Bloc.observer.onError`;
2. feature `onErrorObserver`;
3. `onErrorState` conversion.

Preserve the original error and stack trace for observers. Avoid reporting the
same exception to one telemetry backend from both observer layers. Ensure the
error state is visible rather than hidden by retained loading.

Read [Errors and observers](../../../docs/guides/errors-and-observers.md) when
debugging telemetry, loading/error rendering, or error mapping.

## Assign One Lifecycle Owner

Return every bloc-owned repository or service subscription from
`initSubscriptions`. Remember that the override runs from the base constructor;
read only dependencies initialized before the superclass uses it.

Choose exactly one owner:

- `BlocProvider(create: ...)` for a provider-created instance;
- GetIt for a registered `Disposable` singleton or scoped instance;
- explicit `close` in tests and non-widget runtimes.

Use `BlocProvider.value` for a borrowed GetIt-owned bloc. Do not manually close
an instance that another owner will dispose.

Read [Subscriptions and disposal](../../../docs/guides/subscriptions-and-disposal.md)
for leaks, early close, scope reset, or shared-instance work.

## Test the Behavioral Boundary

Use controlled completers or streams instead of real delays. Cover:

- state precedence, copy, and domain emptiness;
- event loading, success, and error emissions;
- selected overlap behavior;
- global and feature observer delivery;
- subscription cancellation and the real owner cleanup path;
- widget rendering only for integration behavior.

Read [Testing](../../../docs/guides/testing.md) before adding or repairing tests.

## Maintain the Package as One Product

When changing public behavior, inspect and update together:

- `lib/ff_bloc.dart` exports and relevant `lib/src/bloc/` implementation;
- package tests and the runnable example;
- `README.md` and topic pages below `docs/`;
- `docs/reference/api.md`;
- Flutter Files templates below `example/templates/new/`;
- `CHANGELOG.md` and package metadata when applicable;
- repo-local skill guidance if the recommended workflow changed.

Do not publish or bump a version unless requested. Use a clean release commit
for the normal publish dry-run; during development, ignore only the known dirty
worktree warning after confirming it is the sole warning.

## Verify

Run checks proportional to the touched layer. For package-wide work, run:

```shell
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
dart doc --dry-run

cd example
flutter test
cd ..

python3 -m venv build/docs-venv
build/docs-venv/bin/python -m pip install --requirement requirements-docs.txt
build/docs-venv/bin/python -m mkdocs build --strict
flutter pub publish --dry-run
git diff --check
```

Report the selected concurrency policy, state and lifecycle decisions, exact
tests, documentation build result, and any release step intentionally deferred.
