#' Compare multiple synthesis methods
#'
#' Runs all three synthesis methods on the same data and returns
#' a comparative validation table.
#'
#' @param data A data frame of real data.
#' @param n Number of synthetic records. Default: same as input.
#' @param seed Random seed.
#'
#' @return A tibble with columns: method, metric, value,
#'   interpretation.
#'
#' @references
#' Jordon J, et al. (2022). Synthetic Data -- what, why and how?
#' \emph{Nature Machine Intelligence}, 4:805--813.
#' \doi{10.1038/s42256-022-00534-z}
#'
#' @export
#' @examples
#' set.seed(42)
#' real <- data.frame(x = rnorm(100), y = rnorm(100))
#' compare_methods(real)
compare_methods <- function(data, n = nrow(data), seed = 42) {
    methods <- c("parametric", "bootstrap", "noise")
    results <- lapply(methods, function(m) {
        syn <- synthesize(data, method = m, n = n, seed = seed)
        val <- validate_synthetic(syn)
        val$method_used <- m
        val
    })
    out <- dplyr::bind_rows(results)
    out <- out[, c("method_used", "metric", "value",
                    "interpretation")]
    names(out)[1] <- "method"
    structure(out, class = c("method_comparison",
                              class(tibble::tibble())))
}

#' @export
print.method_comparison <- function(x, ...) {
    cli::cli_h3("Synthesis method comparison")
    NextMethod()
}
