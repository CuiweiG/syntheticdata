#' @title syntheticdata: Synthetic Clinical Data Generation
#'
#' @description
#' Generates privacy-preserving synthetic clinical datasets and
#' validates their statistical fidelity. Designed for GDPR/HIPAA
#' compliant data sharing in multi-site clinical research.
#'
#' @importFrom rlang .data %||%
#' @importFrom stats rnorm runif cor var sd quantile ecdf
#' @keywords internal
"_PACKAGE"
