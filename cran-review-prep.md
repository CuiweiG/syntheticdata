# CRAN Pre-Flight Audit Report: syntheticdata

**Date:** 2026-04-06  
**R version:** 4.5.3 (2026-03-11 ucrt)  
**Platform:** x86_64-w64-mingw32 (Windows 10 x64)

------------------------------------------------------------------------

## Summary

| Category | Issues Found | Auto-Fixed | Needs Human Review |
|----------|:------------:|:----------:|:------------------:|
| FORMAT   |      1       |     1      |         0          |
| URL      |      0       |     —      |         0          |
| CHECK    |      1       |     1      |         0          |
| DONTRUN  |      0       |     —      |         0          |
| EXAMPLES |      0       |     —      |         0          |
| CONSOLE  |      0       |     —      |         0          |

**Overall status: ✅ CRAN-ready after version bump**

------------------------------------------------------------------------

## Detailed Findings

### \[CHECK\] R CMD check –as-cran

**1 WARNING:**

    Maintainer: 'Cuiwei Gao <48gaocuiwei@gmail.com>'
    Insufficient package version (submitted: 0.1.0, existing: 0.1.0)
    Days since last update: 4

- **Cause:** Package already exists on CRAN at version 0.1.0. A
  resubmission requires a version bump.
- **Fix:** Bump version to 0.1.1.
- **Status:** ✅ Auto-fixed

**All other checks passed** — no ERRORs, no NOTEs beyond the version
issue.

### \[FORMAT\] DESCRIPTION

- **Title:** “Synthetic Clinical Data Generation and Privacy-Preserving
  Validation” — ✅ Title case, no leading package name, 64 chars, no
  trailing period
- **<Authors@R>:** Uses proper
  [`person()`](https://rdrr.io/r/utils/person.html) format with
  aut/cre/cph roles — ✅
- **License:** `MIT + file LICENSE` — ✅ Valid CRAN license
- **Version:** 0.1.0 → needs bump to 0.1.1 (see CHECK above)
- **Description field:** Well-written, includes references with DOIs —
  ✅
- **Encoding/Language:** UTF-8, en-US — ✅

### \[URL\] Link Check

| URL                                                                          | Status                                                         |
|------------------------------------------------------------------------------|----------------------------------------------------------------|
| <https://github.com/CuiweiG/syntheticdata>                                   | ✅ 200                                                         |
| <https://github.com/CuiweiG/syntheticdata/issues>                            | ✅ 200                                                         |
| <https://github.com/CuiweiG/syntheticdata/actions/workflows/R-CMD-check.yml> | ✅ 200                                                         |
| <https://opensource.org/licenses/MIT>                                        | ✅ 200                                                         |
| <https://doi.org/10.48550/arXiv.2205.03257>                                  | ✅ 200 (→ arxiv.org)                                           |
| <https://doi.org/10.1111/rssa.12358>                                         | ✅ Valid DOI (403 from curl = Wiley anti-bot, not a dead link) |

**No dead links found.**

### \[DONTRUN\] vs Audit

- Searched all `.Rd` files and `.R` source files
- **No `\dontrun{}` usage found anywhere** — ✅
- All examples run directly without wrappers

### \[EXAMPLES\] Example Timing

| Function                                                                                          | Data Size        | Operations               | Estimated Time |
|---------------------------------------------------------------------------------------------------|------------------|--------------------------|----------------|
| [`synthesize()`](https://cuiweig.github.io/syntheticdata/reference/synthesize.md)                 | 200 rows, 4 cols | Copula synthesis         | \< 1s ✅       |
| [`validate_synthetic()`](https://cuiweig.github.io/syntheticdata/reference/validate_synthetic.md) | 100 rows, 2 cols | KS + AUC + NN            | \< 1s ✅       |
| [`compare_methods()`](https://cuiweig.github.io/syntheticdata/reference/compare_methods.md)       | 100 rows, 2 cols | 3× synthesize + validate | \< 2s ✅       |
| [`privacy_risk()`](https://cuiweig.github.io/syntheticdata/reference/privacy_risk.md)             | 100 rows, 2 cols | NN ratio + membership    | \< 1s ✅       |
| [`model_fidelity()`](https://cuiweig.github.io/syntheticdata/reference/model_fidelity.md)         | 200 rows, 3 cols | GLM fit + predict        | \< 1s ✅       |

**No examples exceed 5-second threshold.**

### \[CONSOLE\] print()/cat() Audit

- Searched all R source files for
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`cat()`](https://rdrr.io/r/base/cat.html) calls
- **No bare [`print()`](https://rdrr.io/r/base/print.html) or
  [`cat()`](https://rdrr.io/r/base/cat.html) calls found** — ✅
- All print methods are proper S3 methods (`print.synthetic_data`,
  `print.synthetic_validation`, `print.method_comparison`,
  `print.privacy_assessment`) using
  [`cli::cli_text()`](https://cli.r-lib.org/reference/cli_text.html) /
  [`cli::cli_h3()`](https://cli.r-lib.org/reference/cli_h1.html) — fully
  compliant

------------------------------------------------------------------------

## Auto-Fixes Applied

1.  **Version bump:** DESCRIPTION `Version: 0.1.0` → `Version: 0.1.1`

## Items Requiring Human Review

**None.** The package is clean and CRAN-ready.

------------------------------------------------------------------------

## Notes for Submission

- The `cran-comments.md` file should be updated to mention the version
  bump
- All 5 exported functions have complete documentation with `@examples`
- Test suite passes cleanly
- Vignette builds successfully
- No non-standard dependencies; only `cli`, `dplyr`, `stats`, `tibble`
  in Imports
