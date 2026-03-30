#' Generate synthetic data from a real dataset
#'
#' Creates a synthetic version of the input data that preserves
#' marginal distributions and pairwise correlations while adding
#' controlled noise for privacy protection.
#'
#' @param data A data frame of real clinical data.
#' @param method Synthesis method:
#'   * `"parametric"` (default): fits Gaussian copula to continuous
#'     variables, multinomial to categorical. Fast, interpretable.
#'   * `"bootstrap"`: nonparametric resampling with optional noise.
#'   * `"noise"`: adds calibrated Laplace noise to each variable
#'     (differential privacy inspired).
#' @param n Number of synthetic records. Default: same as input.
#' @param noise_level For `method = "noise"`: scale of Laplace noise
#'   relative to variable SD. Default 0.1.
#' @param seed Random seed for reproducibility. If non-NULL, the
#'   global RNG state is saved before and restored after synthesis
#'   so that calling code is not affected.
#'
#' @return A `synthetic_data` object (list) with:
#'   `$synthetic` (tibble), `$method`, `$n_original`, `$n_synthetic`,
#'   `$variables`.
#'
#' @details
#' The parametric method uses a Gaussian copula approach: marginal
#' distributions are estimated empirically and the joint dependence
#' structure is captured via the correlation matrix of normal scores.
#' This preserves both marginal shapes and pairwise associations
#' while generating genuinely new observations.
#'
#' @references
#' Jordon J, et al. (2022). Synthetic Data -- what, why and how?
#' \emph{Nature Machine Intelligence}, 4:805--813.
#' \doi{10.1038/s42256-022-00534-z}
#'
#' @examples
#' set.seed(42)
#' real <- data.frame(
#'   age = rnorm(200, 65, 10),
#'   sbp = rnorm(200, 130, 20),
#'   sex = sample(c("M", "F"), 200, replace = TRUE),
#'   outcome = rbinom(200, 1, 0.3)
#' )
#' syn <- synthesize(real, method = "parametric", seed = 42)
#' syn
#'
#' @export
synthesize <- function(data, method = c("parametric", "bootstrap", "noise"),
                       n = nrow(data), noise_level = 0.1, seed = NULL) {
  method <- match.arg(method)
  if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")

  if (!is.null(seed)) {
    old_seed <- if (exists(".Random.seed", envir = globalenv()))
      get(".Random.seed", envir = globalenv()) else NULL
    on.exit({
      if (is.null(old_seed)) {
        rm(".Random.seed", envir = globalenv())
      } else {
        assign(".Random.seed", old_seed, envir = globalenv())
      }
    }, add = TRUE)
    set.seed(seed)
  }

  vars <- names(data)
  n_orig <- nrow(data)
  num_cols <- vapply(data, is.numeric, logical(1))

  syn_df <- switch(method,
    parametric = .synth_parametric(data, n, num_cols),
    bootstrap  = .synth_bootstrap(data, n, noise_level, num_cols),
    noise      = .synth_noise(data, n, noise_level, num_cols)
  )

  structure(list(
    synthetic  = tibble::as_tibble(syn_df),
    real       = tibble::as_tibble(data),
    method     = method,
    n_original = n_orig,
    n_synthetic = n,
    variables  = vars
  ), class = "synthetic_data")
}

#' @noRd
.synth_parametric <- function(data, n, num_cols) {
  out <- data.frame(row.names = seq_len(n))

  # Continuous: Gaussian copula
  if (any(num_cols)) {
    num_data <- as.matrix(data[, num_cols, drop = FALSE])
    # Rank -> normal scores
    u <- apply(num_data, 2, function(x) {
      r <- rank(x, ties.method = "random") / (length(x) + 1)
      qnorm(r)
    })
    sigma <- cor(u)
    # Ensure positive-definite
    sigma <- tryCatch(chol(sigma), error = function(e) {
      ev <- eigen(sigma, symmetric = TRUE)
      ev$values <- pmax(ev$values, 1e-6)
      chol(ev$vectors %*% diag(ev$values) %*% t(ev$vectors))
    })
    z <- matrix(rnorm(n * sum(num_cols)), nrow = n) %*% sigma
    # Back to original marginals via inverse CDF
    for (j in seq_len(ncol(z))) {
      col_name <- names(which(num_cols))[j]
      orig <- data[[col_name]]
      u_syn <- pnorm(z[, j])
      out[[col_name]] <- quantile(orig, probs = u_syn, type = 7,
                                   names = FALSE)
    }
  }

  # Categorical: multinomial resampling
  cat_cols <- names(data)[!num_cols]
  for (col in cat_cols) {
    probs <- table(data[[col]]) / nrow(data)
    out[[col]] <- sample(names(probs), n, replace = TRUE, prob = probs)
  }

  out[, names(data), drop = FALSE]
}

#' @noRd
.synth_bootstrap <- function(data, n, noise_level, num_cols) {
  idx <- sample(nrow(data), n, replace = TRUE)
  syn <- data[idx, , drop = FALSE]
  rownames(syn) <- NULL
  for (col in names(data)[num_cols]) {
    syn[[col]] <- syn[[col]] + rnorm(n, 0, noise_level * sd(data[[col]]))
  }
  syn
}

#' @noRd
.synth_noise <- function(data, n, noise_level, num_cols) {
  idx <- sample(nrow(data), n, replace = TRUE)
  syn <- data[idx, , drop = FALSE]
  rownames(syn) <- NULL
  for (col in names(data)[num_cols]) {
    scale_param <- noise_level * sd(data[[col]])
    u <- runif(n) - 0.5
    noise <- -scale_param * sign(u) * log(1 - 2 * abs(u))
    syn[[col]] <- syn[[col]] + noise
  }
  syn
}

#' @export
print.synthetic_data <- function(x, ...) {
  cli::cli_h3("Synthetic data ({x$method})")
  cli::cli_text("{x$n_original} real -> {x$n_synthetic} synthetic records")
  cli::cli_text("Variables: {paste(x$variables, collapse = ', ')}")
  invisible(x)
}
