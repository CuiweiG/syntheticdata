# Generating and validating synthetic clinical data

## Motivation

Sharing individual-level clinical data across institutions is often
restricted by privacy regulations and institutional review boards.
Synthetic data preserves the statistical properties of real data while
reducing re-identification risk, enabling multi-site collaboration
without data transfer.

## Example: synthesizing patient records

``` r
library(syntheticdata)
```

``` r
set.seed(42)
real <- data.frame(
  age     = rnorm(500, mean = 65, sd = 12),
  sbp     = rnorm(500, mean = 135, sd = 22),
  sex     = sample(c("Male", "Female"), 500, replace = TRUE),
  smoking = sample(c("Never", "Former", "Current"), 500,
                   replace = TRUE, prob = c(0.4, 0.35, 0.25)),
  outcome = rbinom(500, 1, 0.28)
)
head(real)
#>        age      sbp    sex smoking outcome
#> 1 81.45150 157.6411   Male   Never       0
#> 2 58.22362 155.1250 Female Current       1
#> 3 69.35754 134.9460   Male   Never       0
#> 4 72.59435 137.9922   Male  Former       0
#> 5 69.85122 119.1566 Female Current       0
#> 6 63.72651 130.6413 Female  Former       0
```

## Parametric synthesis (Gaussian copula)

The default method estimates marginal distributions empirically and
captures the joint dependence structure via a Gaussian copula on normal
scores. This preserves both marginal shapes and pairwise correlations.

``` r
syn <- synthesize(real, method = "parametric", n = 500, seed = 1)
syn
#> 
#> ── Synthetic data (parametric)
#> 500 real -> 500 synthetic records
#> Variables: age, sbp, sex, smoking, outcome
```

## Validation

[`validate_synthetic()`](https://cuiweig.github.io/syntheticdata/reference/validate_synthetic.md)
computes four classes of metrics:

``` r
val <- validate_synthetic(syn)
val
#> 
#> ── Synthetic data validation
#> ks_statistic_mean: 0.0247 (Good fidelity)
#> correlation_diff: 0.0141 (Excellent)
#> discriminative_auc: 0.5117 (Indistinguishable)
#> nn_distance_ratio: 0.8595 (Moderate risk)
```

- **KS statistic**: distributional similarity (lower is better).
- **Correlation difference**: preservation of variable associations.
- **Discriminative AUC**: can a classifier distinguish real from
  synthetic? Values near 0.5 mean indistinguishable.
- **NN distance ratio**: privacy metric. Values above 1 indicate
  synthetic records are not memorizing real individuals.

## Comparing methods

[`compare_methods()`](https://cuiweig.github.io/syntheticdata/reference/compare_methods.md)
runs all three synthesis methods on the same data and returns a single
comparison table:

``` r
comp <- compare_methods(real, seed = 1)
comp
#> 
#> ── Synthesis method comparison
#> # A tibble: 12 × 4
#>    method     metric              value interpretation   
#>  * <chr>      <chr>               <dbl> <chr>            
#>  1 parametric ks_statistic_mean  0.0247 Good fidelity    
#>  2 parametric correlation_diff   0.0141 Excellent        
#>  3 parametric discriminative_auc 0.512  Indistinguishable
#>  4 parametric nn_distance_ratio  0.988  Moderate risk    
#>  5 bootstrap  ks_statistic_mean  0.142  Acceptable       
#>  6 bootstrap  correlation_diff   0.0181 Excellent        
#>  7 bootstrap  discriminative_auc 0.505  Indistinguishable
#>  8 bootstrap  nn_distance_ratio  1.09   Good privacy     
#>  9 noise      ks_statistic_mean  0.135  Acceptable       
#> 10 noise      correlation_diff   0.0162 Excellent        
#> 11 noise      discriminative_auc 0.501  Indistinguishable
#> 12 noise      nn_distance_ratio  1.36   Good privacy
```

## Privacy risk assessment

[`privacy_risk()`](https://cuiweig.github.io/syntheticdata/reference/privacy_risk.md)
provides a deeper privacy audit with three metrics: nearest-neighbor
distance ratio, membership inference accuracy, and (optionally)
attribute disclosure risk for sensitive columns.

``` r
pr <- privacy_risk(syn, sensitive_cols = "age")
pr
#> 
#> ── Privacy risk assessment
#> [!] nn_distance_ratio: 1.0682 (Medium)
#> [OK] membership_inference_acc: 0.497 (Low)
#> [OK] attribute_disclosure_age: 2e-04 (Low)
```

## Downstream model fidelity

[`model_fidelity()`](https://cuiweig.github.io/syntheticdata/reference/model_fidelity.md)
trains a predictive model on synthetic data and evaluates it on real
data. The real-data baseline uses in-sample evaluation as an upper
bound.

``` r
mf <- model_fidelity(syn, outcome = "outcome")
mf
#> # A tibble: 2 × 3
#>   train_data metric value
#>   <chr>      <chr>  <dbl>
#> 1 real       auc    0.523
#> 2 synthetic  auc    0.502
```

A synthetic-trained model with AUC close to the real-trained baseline
indicates that the synthetic data preserves the predictive signal.

## Privacy-utility trade-off

Higher `noise_level` improves privacy but reduces utility:

``` r
results <- list()
for (nl in c(0.05, 0.1, 0.2, 0.5)) {
  s <- synthesize(real, method = "noise", noise_level = nl, seed = 1)
  v <- validate_synthetic(s)
  results <- c(results, list(data.frame(
    noise_level = nl,
    ks = v$value[v$metric == "ks_statistic_mean"],
    privacy = v$value[v$metric == "nn_distance_ratio"]
  )))
}
do.call(rbind, results)
#>   noise_level        ks   privacy
#> 1        0.05 0.1373333 0.7011986
#> 2        0.10 0.1346667 1.3123723
#> 3        0.20 0.1393333 1.9435324
#> 4        0.50 0.1673333 4.6841489
```
