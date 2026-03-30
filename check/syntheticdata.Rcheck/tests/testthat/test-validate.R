test_that("validate_synthetic returns all metrics", {
  set.seed(42)
  real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20))
  syn <- synthesize(real, seed = 1)
  val <- validate_synthetic(syn)
  expect_s3_class(val, "synthetic_validation")
  expect_true(all(c("metric", "value", "interpretation") %in% names(val)))
  expect_true(nrow(val) >= 3)
  expect_no_error(print(val))
})

test_that("good synthetic data has low KS and AUC near 0.5", {
  set.seed(42)
  real <- data.frame(x = rnorm(500), y = rnorm(500))
  syn <- synthesize(real, seed = 1)
  val <- validate_synthetic(syn)
  ks <- val$value[val$metric == "ks_statistic_mean"]
  auc <- val$value[val$metric == "discriminative_auc"]
  expect_lt(ks, 0.3)           # reasonable fidelity
  expect_lt(abs(auc - 0.5), 0.2)  # not too distinguishable
})
