test_that("privacy_risk returns expected metrics", {
  set.seed(42)
  real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20))
  syn <- synthesize(real, seed = 1)
  pr <- privacy_risk(syn)
  expect_s3_class(pr, "privacy_assessment")
  expect_true("nn_distance_ratio" %in% pr$metric)
  expect_true("membership_inference_acc" %in% pr$metric)
  expect_true(all(c("metric", "value", "risk_level") %in% names(pr)))
  expect_no_error(print(pr))
})

test_that("attribute disclosure works with sensitive_cols", {
  set.seed(42)
  real <- data.frame(age = rnorm(80, 65, 10), sbp = rnorm(80, 130, 20))
  syn <- synthesize(real, seed = 1)
  pr <- privacy_risk(syn, sensitive_cols = "age")
  expect_true(any(grepl("attribute_disclosure", pr$metric)))
})
