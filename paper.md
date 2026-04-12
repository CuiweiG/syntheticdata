# Summary

`syntheticdata` is an R package for generating synthetic clinical
datasets that preserve the statistical properties of original
patient-level data while reducing re-identification risk. The package
implements three synthesis engines — Gaussian copula (parametric),
bootstrap resampling with Gaussian noise, and Laplace perturbation — and
provides integrated validation tools for assessing distributional
fidelity, correlation preservation, discriminative indistinguishability,
and privacy risk. A model fidelity function enables direct comparison of
predictive models trained on synthetic versus real data, closing the
loop between data generation and downstream analytical utility.

# Statement of Need

Multi-site clinical research increasingly depends on pooling
patient-level data across institutions, yet regulatory frameworks impose
substantial barriers to sharing identifiable health information. The
General Data Protection Regulation (GDPR) in Europe and the Health
Insurance Portability and Accountability Act (HIPAA) in the United
States require that personal health data be adequately protected before
transfer \[@regulation2016regulation; @act1996health\].
De-identification approaches — removing direct identifiers, suppressing
rare categories — offer partial solutions but remain vulnerable to
linkage attacks when auxiliary data are available \[@sweeney2002k\].

Synthetic data generation addresses this limitation by producing
entirely new observations that reproduce the joint distribution of the
original dataset without retaining any individual’s record. The core
challenge is establishing, quantitatively, that synthetic data is
simultaneously useful enough for its intended analytical purpose and
private enough to satisfy regulatory and ethical requirements.

Several R packages address adjacent problems. `synthpop`
\[@nowok2016synthpop\] generates synthetic versions of survey and census
data using sequential modelling. `simstudy` \[@goldfeld2020simstudy\]
simulates data from user-specified distributions for trial design.
`simPop` focuses on population-level microsimulation. None of these
packages integrate generation with privacy assessment and downstream
model fidelity testing within a single workflow — the combination that
clinical data sharing teams require when preparing submissions to
institutional review boards or data protection officers.

`syntheticdata` fills this gap with a lightweight, dependency-minimal
implementation designed for the datasets most commonly encountered in
clinical and epidemiological research: moderate-dimensional tables with
mixed continuous and categorical variables.

# Key Features

## Synthesis Engines

The package provides three synthesis methods spanning different points
on the privacy–utility spectrum:

**Parametric synthesis** implements a Gaussian copula approach.
Continuous variables are transformed to normal scores via rank-based
quantile mapping, a correlation matrix is estimated on the transformed
scale, and new observations are sampled from the resulting multivariate
normal distribution before back-transformation through the empirical
quantile function. Categorical variables are resampled with empirical
multinomial probabilities. This method produces genuinely new records —
not resampled rows — and typically achieves the best utility metrics.

**Bootstrap synthesis** resamples observations with replacement and adds
calibrated Gaussian noise to numeric columns, with the noise standard
deviation controlled by a user-specified `noise_level` parameter scaled
relative to each variable’s standard deviation.

**Noise-based synthesis** applies Laplace perturbation following the
mechanism underlying differential privacy \[@dwork2006calibrating\]. The
heavier tails of the Laplace distribution provide stronger privacy
protection at the cost of greater distributional distortion.

## Validation Metrics

[`validate_synthetic()`](https://cuiweig.github.io/syntheticdata/reference/validate_synthetic.md)
computes four complementary metrics:

- **Kolmogorov–Smirnov statistic**: mean KS distance across numeric
  variables, assessing marginal distributional agreement.
- **Correlation difference**: Frobenius norm between real and synthetic
  correlation matrices.
- **Discriminative AUC**: area under the ROC curve for a logistic
  classifier trained to distinguish real from synthetic records. Values
  near 0.5 indicate indistinguishability.
- **Nearest-neighbour distance ratio**: median ratio of
  synthetic-to-real versus real-to-real nearest-neighbour distances.
  Values above 1.0 indicate that synthetic records are not memorising
  real individuals.

## Privacy Auditing

[`privacy_risk()`](https://cuiweig.github.io/syntheticdata/reference/privacy_risk.md)
extends the validation framework with membership inference accuracy —
simulating an adversary attempting to determine whether a specific
record was in the training set — and attribute disclosure risk for
user-specified sensitive columns, measured as the R² of a predictive
model trained on synthetic data and evaluated on real data.

## Model Fidelity

[`model_fidelity()`](https://cuiweig.github.io/syntheticdata/reference/model_fidelity.md)
trains a predictive model (logistic regression for binary outcomes,
linear regression for continuous outcomes) on synthetic data and
evaluates it on held-out real data, comparing performance to a baseline
model trained on real data. This directly tests whether synthetic data
preserves enough signal for downstream prediction tasks.

# Example Usage

``` r
library(syntheticdata)

# Generate synthetic version of clinical cohort
syn <- synthesize(clinical_data, method = "parametric", n = 500, seed = 42)

# Validate distributional fidelity and privacy
val <- validate_synthetic(syn)
val

# Deep privacy audit with sensitive column assessment
pr <- privacy_risk(syn, sensitive_cols = c("age", "diagnosis"))

# Test downstream model preservation
mf <- model_fidelity(syn, outcome = "readmitted",
                     predictors = c("age", "sbp", "comorbidity_count"))

# Compare all synthesis methods
comp <- compare_methods(clinical_data, seed = 42)
```

# Implementation Details

The Gaussian copula implementation uses rank-based normal scores rather
than raw data values, providing robustness to outliers while preserving
marginal rank order. The correlation matrix is regularised via
eigenvalue flooring to ensure positive definiteness. Sampling uses
Cholesky decomposition of the regularised correlation matrix, and
back-transformation uses type-7 quantile interpolation matching R’s
default.

The AUC computation uses the Wilcoxon–Mann–Whitney statistic, avoiding
dependence on external classification libraries. Privacy metrics are
computed on random subsamples (200 records for validation, 100 for
privacy auditing) to maintain computational efficiency on large
datasets.

All functions return S3 objects with informative
[`print()`](https://rdrr.io/r/base/print.html) methods using the `cli`
package, and validation results are structured as tibbles for
programmatic downstream use.

# Dependencies

The package depends only on `cli`, `dplyr`, `tibble`, and base R `stats`
— deliberately avoiding heavy machine learning libraries to ensure fast
installation and broad compatibility across computing environments.

# Availability

`syntheticdata` is available on CRAN at
<https://CRAN.R-project.org/package=syntheticdata> and on GitHub at
<https://github.com/CuiweiG/syntheticdata>. Documentation includes a
vignette covering the complete generation-validation-auditing workflow.

# References
