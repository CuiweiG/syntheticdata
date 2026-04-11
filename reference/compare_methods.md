# Compare multiple synthesis methods

Runs all three synthesis methods on the same data and returns a
comparative validation table.

## Usage

``` r
compare_methods(data, n = nrow(data), seed = NULL)
```

## Arguments

- data:

  A data frame of real data.

- n:

  Number of synthetic records. Default: same as input.

- seed:

  Random seed passed to
  [`synthesize()`](https://cuiweig.github.io/syntheticdata/reference/synthesize.md).

## Value

A `method_comparison` object (tibble) with columns: `method`, `metric`,
`value`, `interpretation`.

## References

Jordon J, et al. (2022). Synthetic Data – what, why and how? *arXiv
preprint* arXiv:2205.03257.
[doi:10.48550/arXiv.2205.03257](https://doi.org/10.48550/arXiv.2205.03257)

## Examples

``` r
set.seed(42)
real <- data.frame(x = rnorm(100), y = rnorm(100))
compare_methods(real, seed = 42)
#> 
#> ── Synthesis method comparison 
#> # A tibble: 12 × 4
#>    method     metric              value interpretation   
#>  * <chr>      <chr>               <dbl> <chr>            
#>  1 parametric ks_statistic_mean  0.085  Good fidelity    
#>  2 parametric correlation_diff   0.0263 Excellent        
#>  3 parametric discriminative_auc 0.532  Indistinguishable
#>  4 parametric nn_distance_ratio  0.889  Moderate risk    
#>  5 bootstrap  ks_statistic_mean  0.08   Good fidelity    
#>  6 bootstrap  correlation_diff   0.122  Poor             
#>  7 bootstrap  discriminative_auc 0.509  Indistinguishable
#>  8 bootstrap  nn_distance_ratio  0.562  Moderate risk    
#>  9 noise      ks_statistic_mean  0.085  Good fidelity    
#> 10 noise      correlation_diff   0.120  Poor             
#> 11 noise      discriminative_auc 0.502  Indistinguishable
#> 12 noise      nn_distance_ratio  0.622  Moderate risk    
```
