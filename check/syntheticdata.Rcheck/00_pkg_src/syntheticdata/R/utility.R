#' Downstream model fidelity test
#'
#' Trains a predictive model on synthetic data and evaluates it
#' on real data. Compares to a model trained on real data (gold
#' standard). Measures whether synthetic data preserves
#' predictive signal.
#'
#' @param x A `synthetic_data` object from [synthesize()].
#' @param outcome Character. Name of the outcome column.
#' @param predictors Character vector (optional). Predictor
#'   columns. Default: all other numeric columns.
#'
#' @return A tibble with columns: `train_data`, `metric`, `value`.
#'   For binary outcomes the metric is AUC; for continuous outcomes
#'   it is R-squared.
#'
#' @export
#' @examples
#' set.seed(42)
#' real <- data.frame(
#'     x1 = rnorm(200), x2 = rnorm(200),
#'     y = rbinom(200, 1, 0.3))
#' syn <- synthesize(real, seed = 42)
#' model_fidelity(syn, outcome = "y")
model_fidelity <- function(x, outcome, predictors = NULL) {
  if (!inherits(x, "synthetic_data"))
    cli::cli_abort("{.arg x} must be a {.cls synthetic_data} object.")
  if (!outcome %in% names(x$real))
    cli::cli_abort("Column {.val {outcome}} not found in data.")

  real <- x$real
  syn  <- x$synthetic

  if (is.null(predictors)) {
    num_cols <- vapply(real, is.numeric, logical(1))
    predictors <- setdiff(names(real)[num_cols], outcome)
  }
  if (length(predictors) == 0)
    cli::cli_abort("No predictors available.")

  formula <- as.formula(
    paste(outcome, "~", paste(predictors, collapse = " + ")))

  is_binary <- all(real[[outcome]] %in% c(0L, 1L, 0, 1))

  .fit_and_eval <- function(train, test, label) {
    if (is_binary) {
      fit <- tryCatch(
        glm(formula, data = train, family = binomial()),
        error = function(e) NULL)
      if (is.null(fit)) {
        return(tibble::tibble(
          train_data = label, metric = "auc", value = NA_real_))
      }
      pred <- predict(fit, newdata = test, type = "response")
      auc <- .compute_auc(pred, test[[outcome]])
      tibble::tibble(train_data = label, metric = "auc", value = auc)
    } else {
      fit <- tryCatch(
        lm(formula, data = train),
        error = function(e) NULL)
      if (is.null(fit)) {
        return(tibble::tibble(
          train_data = label, metric = "r2", value = NA_real_))
      }
      pred <- predict(fit, newdata = test)
      r2 <- cor(pred, test[[outcome]])^2
      tibble::tibble(train_data = label, metric = "r2", value = r2)
    }
  }

  cols <- c(outcome, predictors)
  real_result <- .fit_and_eval(
    as.data.frame(real[, cols]), as.data.frame(real[, cols]), "real")
  syn_result <- .fit_and_eval(
    as.data.frame(syn[, cols]), as.data.frame(real[, cols]), "synthetic")
  dplyr::bind_rows(real_result, syn_result)
}
