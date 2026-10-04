# Ponytail audit — 2026-10-04

Internal cleanup log for the repository-wide Ponytail review. This file is
excluded from the built package with the rest of `data-raw/`.

## Scope

- Remove tracked artifacts and stale code that have no package consumer.
- Simplify duplicated binary-file reading without changing the public API.
- Keep deprecated public functions until their documented lifecycle permits
  removal.
- Keep `inst/scripts/` because the package still declares them as shipped
  reproducibility assets.

## Findings and status

| Finding | Class | Status |
| --- | --- | --- |
| `replication_scripts/` is a stale mirror of project repositories | Dead code | Completed |
| `README.html` is an unreferenced generated preview | Generated artifact | Completed |
| `design/resource-api-mockup.R` documents an API that is now implemented | Dead code | Completed |
| The pkgdown workflow deletes `AGENTS.md` twice | Duplication | Completed |
| `rstudioapi` is unused | Dead dependency | Completed |
| Local `.omx/` state enters source-package builds | Packaging artifact | Completed |
| Binary readers repeat download, temporary-file, and cleanup logic | Duplication | Completed |
| `.readers$xls` is unreachable because `.xls` maps to `xlsx` | Dead code | Completed |
| `effective_ext()` loops over vectorized base functions | Needless complexity | Completed |
| The generic cleaning template contains speculative helpers | YAGNI | Deferred |
| `inst/scripts/` has no runtime caller | Possible dead code | Deferred |

The cleaning template remains deferred because it is an intentionally broad
starter kit. The shipped scripts remain deferred until the package contract no
longer presents them as installed reproducibility assets.

## Behavior lock

- Extended `effective_ext()` tests to cover named and empty vectors.
- Added a binary-reader test that checks extension preservation and temporary-file
  cleanup.
- Ran the focused file-selection tests before and after implementation.
- Ran the full test suite, lint, package documentation checks, and `R CMD check`
  after cleanup.

## Fallback inventory

The file-format preference and non-spatial fallback paths are grounded
compatibility behavior. They are user-visible, tested, and remain unchanged.
No masking fallback or swallowed-error path was found in the cleanup scope.

## Verification

- Focused file-selection tests: 29 passed.
- Full test suite: 130 passed; 17 live-network tests skipped by design.
- `lintr::lint_package()`: no lints.
- `pkgdown::check_pkgdown()`: no problems.
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: passed.
- Independent diff review: no remaining findings after removing one stale
  `rstudioapi` reference from `AGENTS.md`.
