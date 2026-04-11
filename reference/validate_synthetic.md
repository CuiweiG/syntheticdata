# Validate synthetic data quality

Computes utility and privacy metrics comparing synthetic data to the
original real dataset.

## Usage

``` r
validate_synthetic(
  x,
  metrics = c("distributional", "correlation", "discriminative", "privacy")
)
```

## Arguments

- x:

  A `synthetic_data` object from
  [`synthesize()`](https://cuiweig.github.io/syntheticdata/reference/synthesize.md).

- metrics:

  Character vector of metrics:

  - `"distributional"`: KS statistic per numeric variable.

  - `"correlation"`: Frobenius norm of correlation difference.

  - `"discriminative"`: AUC of real-vs-synthetic classifier.

  - `"privacy"`: nearest-neighbor distance ratio.

## Value

A `synthetic_validation` object (tibble) with columns: `metric`,
`value`, `interpretation`.

## Details

Utility metrics assess how well the synthetic data preserves statistical
properties. Privacy metrics assess the risk of re-identification.

Discriminative accuracy near 0.5 means the synthetic data is
indistinguishable from real data. Privacy ratio \> 1 means synthetic
records are not closer to real records than real records are to each
other.

## References

Snoke J, et al. (2018). General and specific utility measures for
synthetic data. *Journal of the Royal Statistical Society A*,
181(3):663–688.
[doi:10.1111/rssa.12358](https://doi.org/10.1111/rssa.12358)

## Examples

``` r
set.seed(42)
real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20))
syn <- synthesize(real, seed = 42)
validate_synthetic(syn)
#> 
#> ── Synthetic data validation 
#> ks_statistic_mean: 0.085 (Good fidelity)
#> correlation_diff: 0.0263 (Excellent)
#> discriminative_auc: 0.5319 (Indistinguishable)
#> nn_distance_ratio: 0.8892 (Moderate risk)
```
