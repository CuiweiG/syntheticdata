#' Compute privacy risk metrics
#'
#' Evaluates re-identification risk of synthetic data through
#' multiple privacy metrics: nearest-neighbor distance ratio,
#' membership inference accuracy, and attribute disclosure risk.
#'
#' @param x A \code{synthetic_data} object from \code{\link{synthesize}}.
#' @param sensitive_cols Character vector (optional). Columns
#'   considered sensitive for attribute disclosure assessment.
#'
#' @return A tibble with columns: metric, value, risk_level.
#'
#' @references
#' Snoke J, et al. (2018). General and specific utility measures
#' for synthetic data. \emph{JRSS-A}, 181(3):663--688.
#' \doi{10.1111/rssa.12358}
#'
#' @export
#' @examples
#' set.seed(42)
#' real <- data.frame(age = rnorm(100, 65, 10),
#'                    sbp = rnorm(100, 130, 20))
#' syn <- synthesize(real, seed = 42)
#' privacy_risk(syn)
privacy_risk <- function(x, sensitive_cols = NULL) {
    if (!inherits(x, "synthetic_data"))
        cli::cli_abort("{.arg x} must be a {.cls synthetic_data} object.")

    real <- x$real
    syn <- x$synthetic
    num_cols <- vapply(real, is.numeric, logical(1))
    results <- list()

    ## 1. Nearest-neighbor distance ratio (from validate)
    if (any(num_cols)) {
        real_mat <- as.matrix(real[, num_cols, drop = FALSE])
        syn_mat <- as.matrix(syn[, num_cols, drop = FALSE])
        sds <- apply(real_mat, 2, stats::sd)
        sds[sds == 0] <- 1
        real_sc <- scale(real_mat, center = TRUE, scale = sds)
        syn_sc <- scale(syn_mat, center = colMeans(real_mat),
                         scale = sds)

        n_sample <- min(100L, nrow(real_sc), nrow(syn_sc))
        si <- sample(nrow(syn_sc), n_sample)
        ri <- sample(nrow(real_sc), n_sample)

        d_sr <- vapply(seq_len(n_sample), function(i) {
            diffs <- sweep(real_sc, 2, syn_sc[si[i], ])
            min(sqrt(rowSums(diffs^2)))
        }, numeric(1))

        d_rr <- vapply(seq_len(n_sample), function(i) {
            diffs <- sweep(real_sc[-ri[i], , drop = FALSE], 2,
                           real_sc[ri[i], ])
            min(sqrt(rowSums(diffs^2)))
        }, numeric(1))

        ratio <- stats::median(d_sr) / stats::median(d_rr)
        results <- c(results, list(tibble::tibble(
            metric = "nn_distance_ratio",
            value = ratio,
            risk_level = ifelse(ratio > 1.5, "Low",
                         ifelse(ratio > 0.8, "Medium", "High"))
        )))
    }

    ## 2. Membership inference (can a classifier tell real from syn?)
    if (any(num_cols)) {
        combined <- rbind(
            data.frame(real[, num_cols, drop = FALSE], .y = 1L),
            data.frame(syn[, num_cols, drop = FALSE], .y = 0L))
        fit <- tryCatch(
            stats::glm(.y ~ ., data = combined,
                        family = stats::binomial()),
            error = function(e) NULL)
        if (!is.null(fit)) {
            pred <- stats::predict(fit, type = "response")
            acc <- mean((pred > 0.5) == combined$.y)
        } else acc <- 0.5

        results <- c(results, list(tibble::tibble(
            metric = "membership_inference_acc",
            value = acc,
            risk_level = ifelse(abs(acc - 0.5) < 0.05, "Low",
                         ifelse(abs(acc - 0.5) < 0.1, "Medium",
                                "High"))
        )))
    }

    ## 3. Attribute disclosure (sensitive col prediction accuracy)
    if (!is.null(sensitive_cols)) {
        for (sc in sensitive_cols) {
            if (!sc %in% names(real)) next
            if (!is.numeric(real[[sc]])) next
            pred_cols <- setdiff(names(real)[num_cols], sc)
            if (length(pred_cols) == 0) next

            # Train on synthetic, predict on real
            formula <- stats::as.formula(paste(sc, "~ ."))
            fit <- tryCatch(
                stats::lm(formula,
                           data = syn[, c(sc, pred_cols)]),
                error = function(e) NULL)
            if (!is.null(fit)) {
                pred <- stats::predict(fit,
                    newdata = real[, pred_cols, drop = FALSE])
                r2 <- stats::cor(pred, real[[sc]])^2
            } else r2 <- 0

            results <- c(results, list(tibble::tibble(
                metric = paste0("attribute_disclosure_", sc),
                value = r2,
                risk_level = ifelse(r2 < 0.3, "Low",
                             ifelse(r2 < 0.6, "Medium", "High"))
            )))
        }
    }

    out <- dplyr::bind_rows(results)
    structure(out, class = c("privacy_assessment",
                              class(tibble::tibble())))
}

#' @export
print.privacy_assessment <- function(x, ...) {
    cli::cli_h3("Privacy risk assessment")
    for (i in seq_len(nrow(x))) {
        icon <- switch(x$risk_level[i],
            Low = "\u2705", Medium = "\u26A0\uFE0F",
            High = "\u274C", "\u2753")
        cli::cli_text("  {icon} {x$metric[i]}: {round(x$value[i], 4)} ({x$risk_level[i]})")
    }
    invisible(x)
}
