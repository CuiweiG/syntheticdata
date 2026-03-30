#' Validate synthetic data quality
#'
#' Computes utility and privacy metrics comparing synthetic data
#' to the original real dataset.
#'
#' @param x A `synthetic_data` object from [synthesize()].
#' @param metrics Character vector of metrics:
#'   * `"distributional"`: KS statistic per numeric variable.
#'   * `"correlation"`: Frobenius norm of correlation difference.
#'   * `"discriminative"`: AUC of real-vs-synthetic classifier.
#'   * `"privacy"`: nearest-neighbor distance ratio.
#'
#' @return A `synthetic_validation` object (tibble) with columns:
#'   `metric`, `value`, `interpretation`.
#'
#' @details
#' Utility metrics assess how well the synthetic data preserves
#' statistical properties. Privacy metrics assess the risk of
#' re-identification.
#'
#' Discriminative accuracy near 0.5 means the synthetic data is
#' indistinguishable from real data. Privacy ratio > 1 means
#' synthetic records are not closer to real records than real
#' records are to each other.
#'
#' @references
#' Snoke J, et al. (2018). General and specific utility measures
#' for synthetic data. \emph{Journal of the Royal Statistical Society
#' A}, 181(3):663--688. \doi{10.1111/rssa.12358}
#'
#' @examples
#' set.seed(42)
#' real <- data.frame(age = rnorm(100, 65, 10), sbp = rnorm(100, 130, 20))
#' syn <- synthesize(real, seed = 42)
#' validate_synthetic(syn)
#'
#' @export
validate_synthetic <- function(x,
                               metrics = c("distributional", "correlation",
                                           "discriminative", "privacy")) {
  if (!inherits(x, "synthetic_data"))
    cli::cli_abort("{.arg x} must be a {.cls synthetic_data} object.")

  metrics <- match.arg(metrics, several.ok = TRUE)
  real <- x$real
  syn  <- x$synthetic
  num_cols <- vapply(real, is.numeric, logical(1))

  results <- list()

  if ("distributional" %in% metrics && any(num_cols)) {
    ks_vals <- vapply(names(real)[num_cols], function(col) {
      suppressWarnings(ks.test(real[[col]], syn[[col]])$statistic)
    }, numeric(1))
    results <- c(results, list(tibble::tibble(
      metric = "ks_statistic_mean",
      value  = unname(mean(ks_vals)),
      interpretation = ifelse(mean(ks_vals) < 0.1, "Good fidelity",
                       ifelse(mean(ks_vals) < 0.2, "Acceptable", "Poor"))
    )))
  }

  if ("correlation" %in% metrics && sum(num_cols) >= 2) {
    cor_real <- cor(real[, num_cols, drop = FALSE], use = "complete.obs")
    cor_syn  <- cor(syn[, num_cols, drop = FALSE], use = "complete.obs")
    frob <- sqrt(sum((cor_real - cor_syn)^2)) / length(cor_real)
    results <- c(results, list(tibble::tibble(
      metric = "correlation_diff",
      value  = frob,
      interpretation = ifelse(frob < 0.05, "Excellent",
                       ifelse(frob < 0.1, "Good", "Poor"))
    )))
  }

  if ("discriminative" %in% metrics && any(num_cols)) {
    combined <- rbind(
      data.frame(real[, num_cols, drop = FALSE], .label = 1L),
      data.frame(syn[, num_cols, drop = FALSE], .label = 0L)
    )
    fit <- tryCatch(
      glm(.label ~ ., data = combined, family = binomial()),
      error = function(e) NULL, warning = function(w) {
        suppressWarnings(glm(.label ~ ., data = combined,
                              family = binomial()))
      }
    )
    if (!is.null(fit)) {
      pred <- predict(fit, type = "response")
      lab  <- combined$.label
      auc  <- .compute_auc(pred, lab)
    } else {
      auc <- 0.5
    }
    results <- c(results, list(tibble::tibble(
      metric = "discriminative_auc",
      value  = auc,
      interpretation = ifelse(abs(auc - 0.5) < 0.05, "Indistinguishable",
                       ifelse(abs(auc - 0.5) < 0.1, "Acceptable",
                              "Distinguishable"))
    )))
  }

  if ("privacy" %in% metrics && any(num_cols)) {
    real_mat <- as.matrix(real[, num_cols, drop = FALSE])
    syn_mat  <- as.matrix(syn[, num_cols, drop = FALSE])
    sds <- apply(real_mat, 2, sd)
    sds[sds == 0] <- 1
    real_sc <- scale(real_mat, center = TRUE, scale = sds)
    syn_sc  <- scale(syn_mat, center = colMeans(real_mat), scale = sds)

    n_sample <- min(200L, nrow(real_sc), nrow(syn_sc))
    ri <- sample(nrow(real_sc), n_sample)
    si <- sample(nrow(syn_sc), n_sample)

    d_sr <- vapply(seq_len(n_sample), function(i) {
      diffs <- sweep(real_sc, 2, syn_sc[si[i], ])
      min(sqrt(rowSums(diffs^2)))
    }, numeric(1))

    d_rr <- vapply(seq_len(n_sample), function(i) {
      diffs <- sweep(real_sc[-ri[i], , drop = FALSE], 2, real_sc[ri[i], ])
      min(sqrt(rowSums(diffs^2)))
    }, numeric(1))

    ratio <- median(d_sr) / median(d_rr)
    results <- c(results, list(tibble::tibble(
      metric = "nn_distance_ratio",
      value  = ratio,
      interpretation = ifelse(ratio > 1, "Good privacy",
                       ifelse(ratio > 0.5, "Moderate risk", "High risk"))
    )))
  }

  out <- dplyr::bind_rows(results)
  structure(out, class = c("synthetic_validation", class(tibble::tibble())))
}

#' Compute AUC via Wilcoxon-Mann-Whitney statistic
#' @noRd
.compute_auc <- function(pred, lab) {
  n1 <- sum(lab == 1)
  n0 <- sum(lab == 0)
  if (n1 == 0 || n0 == 0) return(0.5)
  r <- rank(pred)
  (sum(r[lab == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

#' @export
print.synthetic_validation <- function(x, ...) {
  cli::cli_h3("Synthetic data validation")
  for (i in seq_len(nrow(x))) {
    cli::cli_text(
      "  {x$metric[i]}: {round(x$value[i], 4)} ({x$interpretation[i]})"
    )
  }
  invisible(x)
}
