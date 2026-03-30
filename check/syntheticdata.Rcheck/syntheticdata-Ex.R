pkgname <- "syntheticdata"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
options(pager = "console")
base::assign(".ExTimings", "syntheticdata-Ex.timings", pos = 'CheckExEnv')
base::cat("name\tuser\tsystem\telapsed\n", file=base::get(".ExTimings", pos = 'CheckExEnv'))
base::assign(".format_ptime",
function(x) {
  if(!is.na(x[4L])) x[1L] <- x[1L] + x[4L]
  if(!is.na(x[5L])) x[2L] <- x[2L] + x[5L]
  options(OutDec = '.')
  format(x[1L:3L], digits = 7L)
},
pos = 'CheckExEnv')

### * </HEADER>
library('syntheticdata')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("compare_methods")
### * compare_methods

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: compare_methods
### Title: Compare multiple synthesis methods
### Aliases: compare_methods

### ** Examples

set.seed(42)
real <- data.frame(x = rnorm(100), y = rnorm(100))
compare_methods(real, seed = 42)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("compare_methods", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("model_fidelity")
### * model_fidelity

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: model_fidelity
### Title: Downstream model fidelity test
### Aliases: model_fidelity

### ** Examples

set.seed(42)
real <- data.frame(
    x1 = rnorm(200), x2 = rnorm(200),
    y = rbinom(200, 1, 0.3))
syn <- synthesize(real, seed = 42)
model_fidelity(syn, outcome = "y")



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("model_fidelity", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("privacy_risk")
### * privacy_risk

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: privacy_risk
### Title: Compute privacy risk metrics
### Aliases: privacy_risk

### ** Examples

set.seed(42)
real <- data.frame(age = rnorm(100, 65, 10),
                   sbp = rnorm(100, 130, 20))
syn <- synthesize(real, seed = 42)
privacy_risk(syn)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("privacy_risk", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("synthesize")
### * synthesize

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: synthesize
### Title: Generate synthetic data from a real dataset
### Aliases: synthesize

### ** Examples

set.seed(42)
real <- data.frame(
  age = rnorm(200, 65, 10),
  sbp = rnorm(200, 130, 20),
  sex = sample(c("M", "F"), 200, replace = TRUE),
  outcome = rbinom(200, 1, 0.3)
)
syn <- synthesize(real, method = "parametric", seed = 42)
syn




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("synthesize", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("validate_synthetic")
### * validate_synthetic

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: validate_synthetic
### Title: Validate synthetic data quality
### Aliases: validate_synthetic

### ** Examples

set.seed(42)
real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20))
syn <- synthesize(real, seed = 42)
validate_synthetic(syn)




base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("validate_synthetic", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
