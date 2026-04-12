# Twitter/X Announcement Thread — syntheticdata

**Tweet 1:** New on CRAN: syntheticdata — an R package for generating
synthetic clinical datasets with built-in privacy auditing. Gaussian
copula, bootstrap, and Laplace noise engines. Five functions, minimal
dependencies, no GPU required. \#rstats \#SyntheticData \#OpenSource

**Tweet 2:** The problem: multi-site clinical studies need data sharing,
but HIPAA/GDPR make it slow and painful. Synthetic data preserves
statistical structure without retaining any individual’s information.
syntheticdata validates both utility and re-identification risk in the
same workflow.

**Tweet 3:**

``` r
syn <- synthesize(clinical_data, method = "parametric")
validate_synthetic(syn)
privacy_risk(syn, sensitive_cols = "diagnosis")
model_fidelity(syn, outcome = "readmitted")
```

Generation → validation → privacy audit → model testing. Four lines.
\#HealthData \#PrivacyPreserving

**Tweet 4:** What sets it apart: no other CRAN package integrates
synthesis + KS/AUC validation + membership inference + attribute
disclosure risk + downstream model fidelity in one pipeline. Built for
teams who need to show an IRB that synthetic records are safe to share.

**Tweet 5:** Install: install.packages(“syntheticdata”) CRAN:
<https://CRAN.R-project.org/package=syntheticdata> Feedback welcome,
especially from clinical data teams navigating GDPR/HIPAA constraints. —
@CuiweiG23 \#ClinicalResearch \#DataPrivacy \#OpenSource
