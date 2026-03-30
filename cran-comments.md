## Resubmission

This is a resubmission. Changes since initial submission:

* Removed `LazyData: true` (no `data/` directory).
* Removed false GDPR/HIPAA compliance claims from package
  description and vignette.
* Removed unused `rlang` from Imports.
* Fixed `set.seed()` global RNG side-effect: seed is now saved
  and restored via `on.exit()`.
* Added tests for `compare_methods()`, `privacy_risk()`, and
  `model_fidelity()` (previously untested).
* Fixed `@return` documentation mismatch in `model_fidelity()`.
* Removed hardcoded `.libPaths()` from `inst/scripts/gen_figures.R`.
* Updated NEWS.md to document all 5 exported functions.
* Cleaned inst/WORDLIST of unused entries.

## R CMD check results
0 errors | 0 warnings | 1 note

The single NOTE is the standard "New submission" notice.

## Test environments
* local Windows 10, R 4.5.3
* GitHub Actions: ubuntu-latest, macos-latest, windows-latest (R release)

## Reverse dependencies
New package, no reverse dependencies.
