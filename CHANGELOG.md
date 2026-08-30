## Unreleased

- Added constructor-level `FFEventConcurrency` policies for sequential,
  concurrent, droppable, and restartable event handling.
- Forwarded `FFGenericBloc` errors to the global `BlocObserver`, matching
  `FFBloc` behavior.
- Reworked the package documentation, example, tests, dependency constraints,
  and release checks.
- Added a Material for MkDocs documentation portal, GitHub Pages deployment,
  and the repo-local `$ff-bloc` Codex skill.

## 1.0.4

- Updated dependencies.

## 1.0.3

- Improved documentation.
- Rewrote event handling to use `bloc_concurrency`.

## 1.0.2

- Fixed forwarding errors to `Bloc.observer.onError`.

## 1.0.1

- Updated the example.

## 1.0.0

- Initial release.
