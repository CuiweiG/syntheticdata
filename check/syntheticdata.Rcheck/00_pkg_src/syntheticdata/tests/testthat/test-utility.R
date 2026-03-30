test_that("model_fidelity works for binary outcome", {
  set.seed(42)
  real <- data.frame(x1 = rnorm(150), x2 = rnorm(150),
                     y = rbinom(150, 1, 0.3))
  syn <- synthesize(real, seed = 1)
  mf <- model_fidelity(syn, outcome = "y")
  expect_true(all(c("real", "synthetic") %in% mf$train_data))
  expect_true(all(mf$metric == "auc"))
  expect_true(all(!is.na(mf$value)))
})

test_that("model_fidelity works for continuous outcome", {
  set.seed(42)
  real <- data.frame(x = rnorm(100), y = rnorm(100))
  syn <- synthesize(real, seed = 1)
  mf <- model_fidelity(syn, outcome = "y")
  expect_true(all(mf$metric == "r2"))
})

test_that("model_fidelity errors on missing outcome", {
  real <- data.frame(x = 1:10)
  syn <- synthesize(real, seed = 1)
  expect_error(model_fidelity(syn, outcome = "missing"))
})
