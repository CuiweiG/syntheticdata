# Positioning of syntheticdata

Last checked: 2026-11-26.

Notes on what syntheticdata does, how it relates to other R packages, and
where its limits are. Statements about syntheticdata refer to the GitHub
version 0.1.1; the CRAN release is 0.1.0, published 2026-04-02 [S22].
Statements about other packages were checked on 2026-11-26 against the
sources listed at the end; the keys in brackets point to that list.

## Summary

- syntheticdata generates a synthetic version of a single data frame with
  one of three simple methods and computes a small set of heuristic utility
  and privacy risk metrics. It imports four packages (cli, dplyr, stats,
  tibble) [S22].
- The main alternative is synthpop by Beata Nowok, Gillian Raab and Chris
  Dibben [S1, S5]. It offers many synthesis models, utility measures from
  the literature (for example pMSE), disclosure measures based on key
  variables, disclosure control tools, and differential privacy options
  for two methods for categorical data [S1, S3]. It is maintained: the
  latest version, 1.9-3, was published on 2026-09-10, and its CRAN checks
  are clean [S1, S7].
- None of the syntheticdata methods gives a formal differential privacy
  guarantee. The "noise" method adds Laplace noise, but its scale is not
  derived from a sensitivity bound and a privacy budget (epsilon).
- Users who plan to share or release synthetic data, whose analyses depend
  on associations that involve categorical variables, or whose data have
  missing values or survival times should prefer synthpop. syntheticdata
  suits quick experiments on mostly numeric data, teaching, and comparing
  simple methods.

## Main alternative: synthpop

### What it does

- Purpose: "A tool for producing synthetic versions of microdata containing
  confidential information" (CRAN Description) [S1].
- Synthesis: most methods synthesize variables one at a time from
  conditional distributions fitted to the original data, using parametric
  models or classification and regression trees; the methods 'sample',
  'ipf' and 'catall' synthesize all variables at once [S1]. Built-in
  methods include cart, ctree, bag, rf and ranger (tree ensembles),
  survctree (trees for duration data), norm, normrank (normal regression
  that preserves the marginal distribution), lognorm, sqrtnorm, cubertnorm,
  logreg, polyreg, polr, sample, passive, nested, satcat, catall and ipf
  [S3]. syn.strata() performs stratified synthesis [S3].
- Utility: utility.gen() compares synthetic and original data with
  propensity scores from logistic or CART models and returns pMSE, S_pMSE
  (ratio of pMSE to its null expectation), PO50 and SPECKS [S3].
  utility.tab() compares tables from the two data sets with measures such
  as Voas-Williamson, Freeman-Tukey, Jensen-Shannon divergence and pMSE
  [S3]. compare.synds() compares univariate distributions, and
  multi.compare() gives graphical multivariate comparisons [S3].
  glm.synds() and lm.synds() fit models to synthetic data, and
  compare.fit.synds() fits the same model to the original data and
  compares the estimates [S3]; the 1.9-3 NEWS mentions printing of the
  mean confidence interval overlap [S4]. The pMSE approach is described in
  Snoke et al. (2018), whose co-authors include the synthpop authors
  [S17].
- Disclosure: disclosure() computes identity disclosure measures for a set
  of key variables (quasi-identifiers) and attribute disclosure measures
  for a target variable; multi.disclosure() repeats this for several
  targets [S3]. Named measures include repU, DiSCO and TCAP [S3]. These
  functions were added in version 1.9-0 [S4], and the measures are
  described in Raab, Nowok and Dibben, "Practical privacy metrics for
  synthetic data" [S6]. replicated.uniques() finds unique records whose
  key combinations are replicated in the synthetic data, and sdc()
  provides labeling, top and bottom coding, smoothing of numeric data and
  removal of unique records [S3].
- Differential privacy: syn.catall() and syn.ipf() take an epsilon
  parameter that sets the scale of the noise added under differential
  privacy (DP), and a delta parameter for Gaussian noise [S3]. The package
  overview describes these as log-linear methods for categorical variables
  that can be made differentially private [S3].
- Other arguments of syn(): cont.na for missing-value codes in continuous
  variables, event for survival data, rules and rvalues for restricted
  values, and visit.sequence for the order of synthesis [S3].
- Reference publication: Nowok, Raab and Dibben (2016), Journal of
  Statistical Software 74(11) [S5].

### Maintenance status (checked 2026-11-26)

- Latest CRAN version: 1.9-3, published 2026-09-10; maintainer Beata
  Nowok [S1].
- Earlier versions in the CRAN archive (archive file dates): 1.9-2
  (2025-07-13), 1.9-1.1 (2025-06-03), 1.9-1 (2025-03-06), 1.9-0
  (2024-12-20), 1.8-0 (2022-08-31); the oldest archived version, 1.0-0,
  is dated 2014-08-18 [S2].
- CRAN checks for 1.9-3: OK on all 13 check flavors (results page updated
  2026-11-26) [S7].
- Listed in the CRAN Task View OfficialStatistics [S1, S8]. Website:
  https://www.synthpop.org.uk/ [S1].

## Other comparable R packages

Listed only if their CRAN page describes synthesis from real data, or
utility or disclosure measures for synthetic or anonymized data. The scope
column summarizes each CRAN page as of 2026-11-26.

| Package | CRAN version (published) | Scope according to its CRAN page | Overlaps with |
|---|---|---|---|
| riskutility | 0.2.0 (2026-09-02) | Disclosure risk and utility metrics for synthetic and anonymized data: CAP, TCAP, distance to closest record (DCR), nearest neighbor distance ratio (NNDR), identical match share (IMS), propensity score analysis; designed for 'simPop' classes [S9] | `validate_synthetic()`, `privacy_risk()` |
| dataganger | 0.8.2 (2026-08-24) | Synthetic data doubles with data profiling, configurable synthesis, utility comparison and disclosure-risk warnings; the page states that outputs aim to reduce direct disclosure risk and do not guarantee privacy [S10] | whole workflow |
| arf | 0.2.5 (2026-09-21) | Adversarial random forests for density estimation and data synthesis with mixed continuous and categorical variables [S11] | `synthesize()` |
| synthesizer | 0.6.0 (2025-11-18) | Synthesis of numeric, categorical, mixed and time series data, with one parameter that trades data quality against privacy [S12] | `synthesize()` |
| sdcMicro | 5.8.2 (2026-06-12) | Statistical disclosure control: anonymization and risk estimation methods for microdata [S13, S15] | `privacy_risk()`, perturbation methods |
| simPop | 2.1.3 (2024-01-08) | Simulation of populations for surveys based on auxiliary data [S14, S16] | synthesis, for a different use case |

## Boundaries

### What syntheticdata does

Synthesis, `synthesize()` in R/synthesize.R:

| `method` | Internal function | What the code does |
|---|---|---|
| `"parametric"` (default) | `.synth_parametric()` | Gaussian copula for numeric columns: ranks (ties broken at random) are turned into normal scores, their correlation matrix is used to draw multivariate normal values, and these are mapped back through the empirical quantile function of each observed variable (`quantile(type = 7)`). Non-numeric columns are sampled independently from their observed frequencies. |
| `"bootstrap"` | `.synth_bootstrap()` | Rows are resampled with replacement and Gaussian noise with standard deviation `noise_level * sd(x)` is added to each numeric column. Non-numeric values are copied from the resampled rows. |
| `"noise"` | `.synth_noise()` | Rows are resampled with replacement and Laplace noise with scale `noise_level * sd(x)` (inverse-CDF sampling) is added to each numeric column. Non-numeric values are copied. |

Metrics:

| Function (file) | Metric | What the code computes |
|---|---|---|
| `validate_synthetic()` (R/validate.R) | `ks_statistic_mean` | Mean two-sample Kolmogorov-Smirnov statistic over numeric columns. |
| | `correlation_diff` | Frobenius norm of the difference between the real and synthetic correlation matrices, divided by the number of matrix entries (p^2). |
| | `discriminative_auc` | Logistic regression with main effects of the numeric columns, separating real from synthetic rows; the AUC (`.compute_auc()`) is computed on the rows used for fitting. |
| | `nn_distance_ratio` | On numeric columns standardized with the real data: median distance from up to 200 sampled synthetic records to their nearest real record, divided by the median distance from up to 200 sampled real records to their nearest other real record. |
| `privacy_risk()` (R/privacy.R) | `nn_distance_ratio` | The same ratio with up to 100 sampled records and different labels. |
| | `membership_inference_acc` | Accuracy (threshold 0.5) of the same real-versus-synthetic logistic regression, on the rows used for fitting. |
| | `attribute_disclosure_<col>` | For each numeric sensitive column: squared correlation between the real values and the predictions of a linear model fitted to the synthetic data, with the other numeric columns as predictors. |
| `model_fidelity()` (R/utility.R) | `auc` or `r2` | The same GLM or linear model is fitted to the synthetic data and to the real data; both fits are evaluated on the real data that were used for synthesis. |
| `compare_methods()` (R/compare.R) | metrics of `validate_synthetic()` | Runs the three methods with default settings. |

Limits that follow from the code:

- Associations that involve a categorical variable are not reproduced by
  the parametric method, and factor columns come back as character
  vectors.
- Numeric values from the parametric method stay within the observed range
  and are interpolated between adjacent observed values, so a single
  extreme value can be approximated in the output, and integer or 0/1
  columns can receive non-integer values. synthpop offers smoothing and
  top and bottom coding for extreme values [S3].
- In the bootstrap and noise methods, each synthetic record is a perturbed
  copy of one real record, and its non-numeric values are copied
  unchanged; with `noise_level = 0` the bootstrap returns exact copies.
  Integer and 0/1 columns, such as a binary outcome, receive continuous
  noise.
- Missing values are not handled: the parametric method stops with an
  error from `quantile()` when a numeric column contains `NA`, and in the
  bootstrap and noise methods one `NA` makes `sd()` return `NA`, so the
  whole synthetic column becomes `NA`.
- The `synthetic_data` object stores the original data in `$real`
  (R/synthesize.R, `synthesize()`). The object must be handled as
  confidential.
- A main-effects logistic regression detects only differences in the means
  of the numeric columns: when the real and synthetic means are equal, the
  maximum likelihood fit has all slopes equal to zero. All three methods
  reproduce the means approximately, so `discriminative_auc` near 0.5 and
  `membership_inference_acc` near 0.5 are expected whether or not spread,
  shape or dependence are reproduced.
- `membership_inference_acc` uses no records outside the synthesis input,
  so it is not a membership inference attack in the usual sense, which
  asks whether a given record was part of the training data [S21].
- `attribute_disclosure_<col>` skips non-numeric sensitive columns without
  a message and has no baseline, such as the same model fitted to the real
  data.
- `model_fidelity()` has no held-out real data; the real-data baseline is
  evaluated in-sample.
- Labels use fixed cut-offs without a cited source (for example KS < 0.1
  "Good fidelity", NN ratio > 1 "Good privacy"). `validate_synthetic()`
  and `privacy_risk()` use different cut-offs for the same NN ratio
  (> 1 "Good privacy" versus > 1.5 "Low" risk). If the logistic
  regression fails, an AUC and an accuracy of 0.5 are reported, which map
  to "Indistinguishable" and "Low" risk.
- The documentation cites Snoke et al. (2018) [S17], which adapts the
  propensity score mean squared error (pMSE) to synthetic data;
  syntheticdata does not compute pMSE. Jordon et al. (2022) [S18] is a
  general overview of synthetic data.

### What synthpop covers that syntheticdata does not

- Conditional synthesis of categorical and numeric variables together,
  with a choice of tree-based, parametric and log-linear models and
  control of the synthesis order [S1, S3].
- Missing-value codes, survival data, restricted values and stratified
  synthesis (cont.na, event with survctree, rules and rvalues,
  syn.strata()) [S3].
- Utility measures from the literature (pMSE, S_pMSE, SPECKS, table-based
  measures) and comparison of model estimates between synthetic and
  original data [S3, S17].
- Identity and attribute disclosure measures defined on key variables
  (repU, DiSCO, TCAP) and disclosure control tools (sdc(),
  replicated.uniques()) [S3, S6].
- Differential privacy options for the catall and ipf methods [S3].

### Differential privacy

None of the three synthesis methods gives a formal differential privacy
(DP) guarantee, and the metrics cannot establish one.

DP is a property of the randomized algorithm: for any two data sets that
differ in one person's record, the probability of any set of outputs may
change by at most a factor of exp(epsilon) [S19, S20]. The Laplace
mechanism achieves epsilon-DP for a numeric function f by adding Laplace
noise with scale Delta_f / epsilon, where the sensitivity Delta_f is the
largest change in f between two such data sets [S19]. Delta_f is a
worst-case quantity over all possible data sets, so it cannot be estimated
from the data at hand. When a record's value is released directly,
Delta_f is the width of the variable's range, which is unbounded unless
values are clipped to public bounds.

- `method = "noise"` (`.synth_noise()`): the Laplace scale is
  `noise_level * sd(x)`. There is no epsilon and no bound on the values,
  and the scale is computed from the confidential data, so no epsilon can
  be attached to it. Rows are resampled with replacement, so one record
  can be released several times with independent noise, and averaging the
  copies reduces the noise. Every numeric attribute of a record is
  released, so privacy loss would add up across attributes even with a
  valid scale. Non-numeric columns are released without noise.
- `method = "bootstrap"` (`.synth_bootstrap()`): Gaussian noise with the
  same data-dependent scale. The Gaussian mechanism also needs a
  sensitivity bound and a pair (epsilon, delta) [S20]. Non-numeric columns
  are copied.
- `method = "parametric"` (`.synth_parametric()`): no noise is added. The
  output is generated from the empirical quantile functions and the
  empirical correlation matrix of normal scores.
- `validate_synthetic()` and `privacy_risk()` describe one synthetic sample.
  An empirical metric cannot show that an algorithm satisfies DP.

A DP version of the noise method would need at least: public bounds and
clipping for each numeric variable; a user-supplied epsilon (and delta for
Gaussian noise) from which the noise scale is computed; privacy accounting
across all released attributes and records, or DP model fitting instead of
record-level noise; and a mechanism for categorical variables. This is a
change of method, not of wording, and would need its own evaluation.

### When to prefer synthpop

- The synthetic data will be shared or released beyond the people who hold
  the original data. synthpop provides disclosure measures and disclosure
  control tools that can support a release review [S3, S6];
  syntheticdata's metrics are heuristics without a decision rule.
- Relationships that involve categorical variables matter, for example
  diagnosis by age or treatment by outcome; most synthpop methods
  synthesize variables one by one from conditional distributions [S1].
- The data contain missing-value codes, survival times, restricted values
  or strata, which syn() and syn.strata() have arguments for [S3].
- Utility should be reported with established measures (pMSE, S_pMSE,
  SPECKS) or by comparing model estimates [S3, S17].
- Differential privacy is required for categorical data; synthpop's catall
  and ipf methods have DP options [S3]. Check their documentation for the
  conditions.

For distance-based risk measures beyond the NN distance ratio (DCR, NNDR,
IMS), riskutility is an option [S9].

### When syntheticdata can be adequate

- Quick experiments on mostly numeric data with few dependencies (its
  Imports field lists 4 packages; synthpop's lists 23) [S1, S22].
- Teaching the privacy-utility trade-off and comparing a Gaussian copula
  with noise-based perturbation through `compare_methods()`, with the
  limits above stated.
- Its metrics should not be used as evidence that a data set is safe to
  share.

## Sources

All accessed 2026-11-26.

- [S1] synthpop on CRAN (Title, Description, version 1.9-3, publication
  date, authors, imports, task views):
  https://CRAN.R-project.org/package=synthpop
- [S2] synthpop CRAN archive (file dates of earlier versions):
  https://CRAN.R-project.org/src/contrib/Archive/synthpop/
- [S3] synthpop reference manual (function index, syn() methods and
  arguments, utility and disclosure measures, syn.catall() and syn.ipf()):
  https://cran.r-project.org/web/packages/synthpop/refman/synthpop.html
- [S4] synthpop NEWS (disclosure() and multi.disclosure() added in 1.9-0;
  changes in 1.9-3): https://cran.r-project.org/web/packages/synthpop/NEWS
- [S5] Nowok B, Raab GM, Dibben C (2016). synthpop: Bespoke Creation of
  Synthetic Data in R. Journal of Statistical Software, 74(11).
  https://doi.org/10.18637/jss.v074.i11
- [S6] Raab GM, Nowok B, Dibben C. Practical privacy metrics for synthetic
  data. arXiv:2406.16826 (version 6, 2026-09-01).
  https://arxiv.org/abs/2406.16826
- [S7] synthpop CRAN check results:
  https://cran.r-project.org/web/checks/check_results_synthpop.html
- [S8] CRAN Task View OfficialStatistics, section "Statistical Disclosure
  Control" (version 2025-03-11):
  https://CRAN.R-project.org/view=OfficialStatistics
- [S9] riskutility on CRAN: https://CRAN.R-project.org/package=riskutility
- [S10] dataganger on CRAN: https://CRAN.R-project.org/package=dataganger
- [S11] arf on CRAN: https://CRAN.R-project.org/package=arf
- [S12] synthesizer on CRAN: https://CRAN.R-project.org/package=synthesizer
- [S13] sdcMicro on CRAN: https://CRAN.R-project.org/package=sdcMicro
- [S14] simPop on CRAN: https://CRAN.R-project.org/package=simPop
- [S15] Templ M, Kowarik A, Meindl B (2015). Statistical Disclosure Control
  for Micro-Data Using the R Package sdcMicro. Journal of Statistical
  Software, 67(4). https://doi.org/10.18637/jss.v067.i04
- [S16] Templ M, Meindl B, Kowarik A, Dupriez O (2017). Simulation of
  Synthetic Complex Data: The R Package simPop. Journal of Statistical
  Software, 79(10). https://doi.org/10.18637/jss.v079.i10
- [S17] Snoke J, Raab GM, Nowok B, Dibben C, Slavkovic A (2018). General
  and Specific Utility Measures for Synthetic Data. Journal of the Royal
  Statistical Society Series A, 181(3), 663-688.
  https://doi.org/10.1111/rssa.12358
- [S18] Jordon J, Szpruch L, Houssiau F, Bottarelli M, Cherubin G,
  Maple C, Cohen SN, Weller A (2022). Synthetic Data -- what, why and how?
  arXiv:2205.03257. https://doi.org/10.48550/arXiv.2205.03257
- [S19] Dwork C, McSherry F, Nissim K, Smith A (2006). Calibrating Noise to
  Sensitivity in Private Data Analysis. Theory of Cryptography (TCC 2006),
  Lecture Notes in Computer Science, 265-284.
  https://doi.org/10.1007/11681878_14
- [S20] Dwork C, Roth A (2014). The Algorithmic Foundations of Differential
  Privacy. Foundations and Trends in Theoretical Computer Science, 9(3-4).
  https://doi.org/10.1561/0400000042
- [S21] Shokri R, Stronati M, Song C, Shmatikov V (2017). Membership
  Inference Attacks Against Machine Learning Models. 2017 IEEE Symposium on
  Security and Privacy, 3-18. https://doi.org/10.1109/SP.2017.41
- [S22] syntheticdata on CRAN (version 0.1.0, imports):
  https://CRAN.R-project.org/package=syntheticdata
