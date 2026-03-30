#' @title syntheticdata: Synthetic Clinical Data Generation and
#'   Privacy-Preserving Validation
#'
#' @description
#' Generates synthetic clinical datasets that preserve statistical
#' properties while reducing re-identification risk. Implements
#' Gaussian copula simulation, bootstrap with noise injection, and
#' Laplace noise perturbation, with built-in utility and privacy
#' validation metrics.
#'
#' @importFrom stats cor ecdf median quantile rnorm runif sd var
#'   as.formula binomial glm lm predict pnorm qnorm ks.test
#' @keywords internal
"_PACKAGE"
