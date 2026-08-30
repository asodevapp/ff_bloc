---
title: Codex skill
description: Use the repo-local ff-bloc Codex skill for implementation, migration, review, debugging, lifecycle, concurrency, and package documentation work.
---

# Codex skill

The repository includes a repo-local `$ff-bloc` skill at
`.agents/skills/ff-bloc/SKILL.md`. Codex can discover it while working in this
checkout.

## Invoke it explicitly

```text
Use $ff-bloc to implement this search feature with restartable loading and tests.
```

Other useful requests:

```text
Use $ff-bloc to review this feature for state-copy and lifecycle bugs.
Use $ff-bloc to migrate this ChangeNotifier feature without changing the UI contract.
Use $ff-bloc to diagnose why this loading state never becomes an error.
Use $ff-bloc to update the package API and keep docs, templates, and tests in sync.
```

## What the skill enforces

- trace the complete event → bloc → repository → state → UI path;
- select concurrency from operation semantics;
- keep restartable cancellation limits explicit;
- preserve `FFState` status and clear semantics;
- choose exactly one lifecycle owner;
- retain global and feature error observation;
- verify changes with focused tests and package-level checks;
- update README, portal docs, templates, API docs, and changelog together when
  public behavior changes.

## Use in another repository

Repo-local skills are versioned with the checkout. A consumer project can vendor
the `ff-bloc` skill under its own `.agents/skills/` directory when the team wants
the same workflow available there. Keep the copied skill aligned with the
package version used by that project.

Do not rely on the skill as runtime documentation. Application source, package
tests, and this documentation remain the authoritative behavior.
