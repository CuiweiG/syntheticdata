# Generate synthetic data from a real dataset

Creates a synthetic version of the input data that preserves marginal
distributions and pairwise correlations while adding controlled noise
for privacy protection.

## Usage

``` r
synthesize(
  data,
  method = c("parametric", "bootstrap", "noise"),
  n = nrow(data),
  noise_level = 0.1,
  seed = NULL
)
```

## Arguments

- data:

  A data frame of real clinical data.

- method:

  Synthesis method:

  - `"parametric"` (default): fits Gaussian copula to continuous
    variables, multinomial to categorical. Fast, interpretable.

  - `"bootstrap"`: nonparametric resampling with optional noise.

  - `"noise"`: adds calibrated Laplace noise to each variable
    (differential privacy inspired).

- n:

  Number of synthetic records. Default: same as input.

- noise_level:

  For `method = "noise"`: scale of Laplace noise relative to variable
  SD. Default 0.1.

- seed:

  Random seed for reproducibility. If non-NULL, the global RNG state is
  saved before and restored after synthesis so that calling code is not
  affected.

## Value

A `synthetic_data` object (list) with components: `$synthetic` (tibble
of synthetic records), `$real` (tibble of the original data, retained
for downstream validation), `$method`, `$n_original`, `$n_synthetic`,
`$variables`.

## Details

The parametric method uses a Gaussian copula approach: marginal
distributions are estimated empirically and the joint dependence
structure is captured via the correlation matrix of normal scores. This
preserves both marginal shapes and pairwise associations while
generating genuinely new observations.

## References

Jordon J, et al. (2022). Synthetic Data – what, why and how? *arXiv
preprint* arXiv:2205.03257.
[doi:10.48550/arXiv.2205.03257](https://doi.org/10.48550/arXiv.2205.03257)

## Examples

``` r
set.seed(42)
real <- data.frame(
  age = rnorm(200, 65, 10),
  sbp = rnorm(200, 130, 20),
  sex = sample(c("M", "F"), 200, replace = TRUE),
  outcome = rbinom(200, 1, 0.3)
)
syn <- synthesize(real, method = "parametric", seed = 42)
syn
#> 
#> ── Synthetic data (parametric) 
#> 200 real -> 200 synthetic records
#> Variables: age, sbp, sex, outcome
```
