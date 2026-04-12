# Privacy Without Paralysis: Generating Synthetic Clinical Data in R

Clinical researchers face a familiar impasse. Multi-site studies require
pooling patient records across institutions, yet privacy regulations —
GDPR in Europe, HIPAA in the United States — impose stringent barriers
on sharing identifiable health data. Ethics boards demand anonymisation;
data use agreements take months to negotiate; and the resulting delays
can stall research at precisely the moment when timely evidence matters
most.

Synthetic data offers a principled way forward. Rather than
de-identifying real records (which can be reversed under certain
conditions), we generate entirely new observations that reproduce the
statistical structure of the original dataset without retaining any
individual’s information. The challenge, of course, is demonstrating
that synthetic data is both *useful enough* to support downstream
analysis and *private enough* to satisfy regulators.

The `syntheticdata` R package, now available on CRAN, was built to
address both concerns within a single workflow. It provides generation,
validation, and privacy auditing in five core functions — no deep
learning infrastructure required, no Python bridges, no GPU
dependencies.

## What the Package Does

Three synthesis engines cover different points on the privacy–utility
spectrum:

- **Parametric synthesis** fits a Gaussian copula to rank-transformed
  observations, preserving both marginal distributions and the full
  correlation structure. This produces genuinely new records — not
  resampled rows — and tends to yield the best utility metrics.
- **Bootstrap synthesis** resamples with replacement and injects
  calibrated Gaussian noise, suitable for data where distributional
  assumptions are unwelcome.
- **Noise-based synthesis** applies Laplace perturbation (the mechanism
  underpinning differential privacy) for settings where privacy
  requirements dominate utility concerns.

The interface is deliberately minimal:

``` r
library(syntheticdata)

# Generate synthetic version of a clinical cohort
syn <- synthesize(clinical_data, method = "parametric", n = 500, seed = 42)
```

The returned object bundles both synthetic and original data, enabling
every subsequent validation step without juggling separate data frames.

## Measuring What Matters

A synthetic dataset is only as good as the evidence supporting its
fidelity and safety.
[`validate_synthetic()`](https://cuiweig.github.io/syntheticdata/reference/validate_synthetic.md)
computes four complementary metrics in a single call:

``` r
val <- validate_synthetic(syn)
val
```

- **Kolmogorov–Smirnov statistic** (distributional fidelity) — mean KS
  across all numeric variables; values below 0.1 indicate close marginal
  agreement.
- **Correlation difference** — Frobenius norm between real and synthetic
  correlation matrices; below 0.05 is excellent.
- **Discriminative AUC** — a logistic classifier attempts to distinguish
  real from synthetic records. An AUC near 0.5 means the classifier
  cannot tell them apart.
- **Nearest-neighbour distance ratio** — the median ratio of
  synthetic-to-real versus real-to-real nearest-neighbour distances.
  Values above 1.0 indicate that synthetic records are not memorising
  real individuals.

For deeper privacy auditing,
[`privacy_risk()`](https://cuiweig.github.io/syntheticdata/reference/privacy_risk.md)
adds membership inference accuracy and attribute disclosure risk for
user-specified sensitive columns:

``` r
pr <- privacy_risk(syn, sensitive_cols = c("age", "diagnosis_code"))
```

## A Complete Reproducible Example

Consider a hypothetical multi-site readmission study. Each site holds
patient-level data with demographics, vitals, and a binary readmission
outcome. Site A wishes to share data with Site B for collaborative model
development, but cannot export identifiable records.

``` r
library(syntheticdata)

# Site A generates synthetic data
syn <- synthesize(site_a_data, method = "parametric", n = 1000, seed = 1)

# Validate utility
validate_synthetic(syn)

# Audit privacy
privacy_risk(syn, sensitive_cols = "age")

# Test whether a model trained on synthetic data
# performs comparably to one trained on real data
model_fidelity(syn, outcome = "readmitted", predictors = c("age", "sbp", "comorbidity_count"))
```

The
[`model_fidelity()`](https://cuiweig.github.io/syntheticdata/reference/model_fidelity.md)
function trains a predictive model on synthetic records, evaluates it on
held-out real data, and compares performance to a real-data baseline. If
the AUC or R-squared values are close, the synthetic data preserves
enough signal for the intended analytical purpose.

When the optimal synthesis strategy is unclear,
[`compare_methods()`](https://cuiweig.github.io/syntheticdata/reference/compare_methods.md)
benchmarks all three engines on the same dataset and returns a
side-by-side comparison table — a practical shortcut for method
selection.

## Where This Fits in the Ecosystem

Several R packages address synthetic data generation. `synthpop` (Nowok,
Raab, and Dibben 2016) targets survey and census data with sequential
modelling. `simstudy` (Goldfeld 2020) simulates from user-specified
distributions for trial design. `simPop` focuses on population-level
microsimulation.

`syntheticdata` occupies a different niche. It starts from observed
clinical data (not user-specified parameters), couples generation with
privacy assessment, and includes downstream model fidelity testing. For
teams that need to demonstrate to an IRB or data protection officer that
synthetic records are both statistically adequate and
re-identification-resistant, this integrated workflow eliminates the
need to stitch together separate tools.

## Practical Considerations

The Gaussian copula approach works well for datasets with moderate
dimensionality and a mix of continuous and categorical variables — a
common profile in clinical research. For very high-dimensional data
(thousands of features), or for complex temporal structures, generative
adversarial networks or sequential synthesis methods may be more
appropriate. The package does not attempt to replace those approaches;
it provides a lightweight, dependency-minimal alternative for the
datasets most commonly encountered in clinical and epidemiological work.

Privacy metrics should be interpreted in context. A nearest-neighbour
distance ratio above 1.0 is reassuring but does not constitute a formal
privacy guarantee in the differential privacy sense. Laplace noise
synthesis moves closer to that standard, though calibrating the noise
parameter ε requires domain-specific judgment about acceptable utility
loss.

## Getting Started

``` r
install.packages("syntheticdata")
```

The package ships with a single vignette walking through the full
generation-validation-auditing pipeline. Source code and issue tracking
are available on [GitHub](https://github.com/CuiweiG/syntheticdata).
Feedback from clinical data teams working under GDPR, HIPAA, or
institutional privacy constraints is particularly welcome — the privacy
metrics and their interpretive thresholds will benefit from validation
across diverse real-world settings.

------------------------------------------------------------------------

*Cuiwei Gao is a health data analyst and R developer. The
`syntheticdata` package is available on
[CRAN](https://CRAN.R-project.org/package=syntheticdata).*
