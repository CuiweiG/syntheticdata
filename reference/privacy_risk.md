# Compute privacy risk metrics

Evaluates re-identification risk of synthetic data through multiple
privacy metrics: nearest-neighbor distance ratio, membership inference
accuracy, and attribute disclosure risk.

## Usage

``` r
privacy_risk(x, sensitive_cols = NULL)
```

## Arguments

- x:

  A `synthetic_data` object from
  [`synthesize`](https://cuiweig.github.io/syntheticdata/reference/synthesize.md).

- sensitive_cols:

  Character vector (optional). Columns considered sensitive for
  attribute disclosure assessment.

## Value

A `privacy_assessment` object (tibble) with columns: `metric`, `value`,
`risk_level`.

## References

Snoke J, et al. (2018). General and specific utility measures for
synthetic data. *Journal of the Royal Statistical Society A*,
181(3):663–688.
[doi:10.1111/rssa.12358](https://doi.org/10.1111/rssa.12358)

## Examples

``` r
set.seed(42)
real <- data.frame(age = rnorm(100, 65, 10),
                   sbp = rnorm(100, 130, 20))
syn <- synthesize(real, seed = 42)
privacy_risk(syn)
#> 
#> ── Privacy risk assessment 
#> [!] nn_distance_ratio: 0.8892 (Medium)
#> [OK] membership_inference_acc: 0.535 (Low)
```
