## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")

## ----setup--------------------------------------------------------------------
library(syntheticdata)

## ----real-data----------------------------------------------------------------
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

## ----synthesize---------------------------------------------------------------
syn <- synthesize(real, method = "parametric", n = 500, seed = 1)
syn

## ----validate-----------------------------------------------------------------
val <- validate_synthetic(syn)
val

## ----compare------------------------------------------------------------------
syn_boot  <- synthesize(real, method = "bootstrap", seed = 2)
syn_noise <- synthesize(real, method = "noise", noise_level = 0.2, seed = 3)

val_boot  <- validate_synthetic(syn_boot)
val_noise <- validate_synthetic(syn_noise)

comparison <- rbind(
  transform(as.data.frame(val),       method = "parametric"),
  transform(as.data.frame(val_boot),  method = "bootstrap"),
  transform(as.data.frame(val_noise), method = "noise")
)
comparison[, c("method", "metric", "value", "interpretation")]

## ----tradeoff-----------------------------------------------------------------
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

