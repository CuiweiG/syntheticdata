test_that("parametric synthesis works", {
  set.seed(42)
  real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20),
                     sex = sample(c("M","F"), 100, replace = TRUE))
  syn <- synthesize(real, method = "parametric", seed = 1)
  expect_s3_class(syn, "synthetic_data")
  expect_equal(nrow(syn$synthetic), 100)
  expect_equal(names(syn$synthetic), names(real))
  expect_no_error(print(syn))
})

test_that("bootstrap synthesis works", {
  real <- data.frame(x = rnorm(50), y = rnorm(50))
  syn <- synthesize(real, method = "bootstrap", seed = 1)
  expect_equal(nrow(syn$synthetic), 50)
})

test_that("noise synthesis works", {
  real <- data.frame(x = rnorm(50), cat = sample(letters[1:3], 50, replace = TRUE))
  syn <- synthesize(real, method = "noise", seed = 1)
  expect_equal(nrow(syn$synthetic), 50)
})

test_that("custom n works", {
  real <- data.frame(x = 1:10)
  syn <- synthesize(real, n = 50, seed = 1)
  expect_equal(nrow(syn$synthetic), 50)
})

test_that("seed gives reproducibility", {
  real <- data.frame(x = rnorm(50))
  s1 <- synthesize(real, seed = 42)
  s2 <- synthesize(real, seed = 42)
  expect_equal(s1$synthetic$x, s2$synthetic$x)
})
