test_that("compare_methods returns all methods and metrics", {
  set.seed(42)
  real <- data.frame(x = rnorm(80), y = rnorm(80))
  comp <- compare_methods(real, seed = 1)
  expect_s3_class(comp, "method_comparison")
  expect_true(all(c("parametric", "bootstrap", "noise") %in% comp$method))
  expect_true(all(c("method", "metric", "value", "interpretation") %in% names(comp)))
  expect_no_error(print(comp))
})
