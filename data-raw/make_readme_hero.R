# Build syntheticdata README hero on real UCI Wisconsin Breast Cancer data.
#
# Data: mlbench::BreastCancer (UCI WDBC; Wolberg & Mangasarian 1990,
#   Wisconsin; public domain).
# Variability: 10 seeds x 3 synthesis methods = 30 runs.
# Downstream task: binary classification of benign/malignant via glm AUC.
# Privacy metric: nearest-neighbour distance ratio
#   (ratio = median(d_syn->real) / median(d_real->real'); formula in
#   syntheticdata::privacy_risk source; ratio > 1 => higher privacy
#   because synthetic records are FARTHER from real records than real
#   records are from their nearest other real record).
#
# Output: man/figures/privacy_utility_hero.png (1400x900 @ 150 dpi).

suppressPackageStartupMessages({
  library(syntheticdata)
  library(ggplot2)
  library(patchwork)
  library(ggrepel)
  library(dplyr)
  library(tidyr)
  library(mlbench)
})

# ---- Load & clean data -----------------------------------------------------

data(BreastCancer, package = "mlbench")
cat("Raw BreastCancer: ", nrow(BreastCancer), " rows x ",
    ncol(BreastCancer), " cols\n", sep = "")

real <- BreastCancer |>
  select(-Id) |>
  filter(complete.cases(across(everything())))

# BreastCancer stores feature values as ordered factors "1".."10"; cast to
# numeric so downstream synthesis and KS tests behave sensibly.
feat_cols <- setdiff(names(real), "Class")
real[feat_cols] <- lapply(real[feat_cols],
                          function(x) as.numeric(as.character(x)))

# Binary outcome (0/1). Keep the Class column so model_fidelity() can use it.
real$Class <- as.integer(real$Class == "malignant")

N <- nrow(real)
P <- length(feat_cols)
prev <- round(mean(real$Class), 3)
cat("Cleaned: N=", N, " features=", P, " malignant prevalence=", prev, "\n",
    sep = "")

# ---- Multi-seed comparison -------------------------------------------------

seeds   <- c(42, 1, 7, 17, 99, 123, 555, 2024, 314, 271)
methods <- c("parametric", "bootstrap", "noise")

results    <- tibble()
per_var_ks <- tibble()

for (m in methods) {
  for (s in seeds) {
    syn_obj <- synthesize(real, method = m, seed = s)

    # Bootstrap / noise synthesisers treat every numeric column as
    # continuous and so return a noisy real-valued Class column.
    # Round it back to 0/1 so the downstream binary-outcome glm in
    # model_fidelity() receives a valid response. This only affects
    # the outcome column; features are left untouched.
    if (m %in% c("bootstrap", "noise")) {
      syn_obj$synthetic$Class <- as.integer(syn_obj$synthetic$Class >= 0.5)
    }

    val     <- validate_synthetic(syn_obj)
    priv    <- privacy_risk(syn_obj)
    fid     <- model_fidelity(syn_obj, outcome = "Class")

    ks_mean <- val$value[val$metric == "ks_statistic_mean"]
    nn_rat  <- priv$value[priv$metric == "nn_distance_ratio"]
    auc_syn  <- fid$value[fid$train_data == "synthetic" & fid$metric == "auc"]
    auc_real <- fid$value[fid$train_data == "real"      & fid$metric == "auc"]

    results <- bind_rows(results, tibble(
      method = m, seed = s,
      fidelity = 1 - ks_mean,
      privacy  = nn_rat,
      auc_syn  = auc_syn,
      auc_real = auc_real
    ))

    # Per-variable KS for Panel C
    for (v in feat_cols) {
      k <- suppressWarnings(
        ks.test(syn_obj$real[[v]], syn_obj$synthetic[[v]])$statistic
      )
      per_var_ks <- bind_rows(per_var_ks, tibble(
        method = m, seed = s, variable = v, ks = unname(k)
      ))
    }
  }
  cat("Method", m, "done\n")
}

# ---- Sanitise: replace infinite privacy ratios (caused by duplicate
# ---- real rows making median(d_rr) = 0) with a capped numerical value
# ---- for plotting. These cases remain reported in the caption.

n_inf <- sum(!is.finite(results$privacy))
cat("\nInfinite / NA privacy ratios:", n_inf, "(will be capped at 6)\n")
results$privacy[!is.finite(results$privacy)] <- 6

cat("\n=== Summary by method (mean across 10 seeds, finite privacy only) ===\n")
summary_by_method <- results |>
  group_by(method) |>
  summarise(
    fidelity_mean = mean(fidelity),
    fidelity_sd   = sd(fidelity),
    privacy_mean  = mean(privacy),
    privacy_sd    = sd(privacy),
    auc_syn_mean  = mean(auc_syn),
    auc_syn_sd    = sd(auc_syn)
  )
print(summary_by_method)

real_baseline_auc <- mean(results$auc_real)
cat("\nReal-data baseline AUC (glm, in-sample):",
    round(real_baseline_auc, 3), "\n")

# ---- Method-label factor for consistent colours ----------------------------

method_labels <- c(
  parametric = "Gaussian copula",
  bootstrap  = "Bootstrap",
  noise      = "Laplace noise"
)
results$method_label    <- factor(method_labels[results$method],
                                   levels = unname(method_labels))
per_var_ks$method_label <- factor(method_labels[per_var_ks$method],
                                   levels = unname(method_labels))

method_colours <- c(
  "Gaussian copula" = "#1565C0",
  "Bootstrap"       = "#E65100",
  "Laplace noise"   = "#6A1B9A"
)

# ---- Panel A: privacy-utility 2D plane ------------------------------------

centroids <- results |>
  group_by(method_label) |>
  summarise(fidelity = mean(fidelity),
            privacy  = mean(privacy),
            .groups  = "drop")

x_lo <- min(results$fidelity, na.rm = TRUE) - 0.02
x_hi <- max(results$fidelity, na.rm = TRUE) + 0.02
y_lo <- min(results$privacy,  na.rm = TRUE) - 0.15
y_hi <- max(results$privacy,  na.rm = TRUE) + 0.25

pA <- ggplot(results, aes(x = fidelity, y = privacy,
                          colour = method_label, fill = method_label)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1, ymax = Inf,
           fill = "#1B5E20", alpha = 0.06) +
  geom_hline(yintercept = 1, linetype = "dashed",
             colour = "grey45", linewidth = 0.45) +
  annotate("text", x = x_lo + 0.002, y = 1,
           label = "Privacy floor (ratio = 1)",
           hjust = 0, vjust = -0.5, size = 3.3, colour = "grey30") +
  annotate("text", x = x_hi - 0.002, y = y_hi - 0.04,
           label = "Higher privacy",
           hjust = 1, size = 3.3, fontface = "italic", colour = "#1B5E20") +
  stat_ellipse(geom = "polygon", alpha = 0.12, level = 0.95,
               linewidth = 0.4) +
  geom_point(size = 2.2, alpha = 0.75) +
  geom_point(data = centroids, aes(x = fidelity, y = privacy,
                                    colour = method_label),
             size = 4.5, shape = 18, show.legend = FALSE) +
  geom_text_repel(data = centroids,
                  aes(label = method_label, colour = method_label),
                  fontface = "bold", size = 4.1,
                  seed = 1, box.padding = 0.8, point.padding = 0.5,
                  min.segment.length = 0, show.legend = FALSE) +
  scale_colour_manual(values = method_colours, name = NULL, guide = "none") +
  scale_fill_manual(values = method_colours, name = NULL, guide = "none") +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(x_lo, x_hi)) +
  scale_y_continuous(limits = c(y_lo, y_hi)) +
  labs(
    title    = "Privacy-utility plane",
    subtitle = "Each point = 1 seed (10 per method); ellipses are 95% CI",
    x = "Distributional fidelity (1 - mean KS)",
    y = "Privacy (NN distance ratio)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(colour = "grey30", size = 10)
  )

# ---- Panel B: downstream AUC -----------------------------------------------

pB <- ggplot(results, aes(x = method_label, y = auc_syn,
                          fill = method_label, colour = method_label)) +
  geom_hline(yintercept = real_baseline_auc,
             linetype = "dashed", colour = "grey40", linewidth = 0.5) +
  geom_boxplot(alpha = 0.3, width = 0.55, outlier.shape = NA,
               linewidth = 0.45) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.85) +
  scale_fill_manual(values = method_colours, guide = "none") +
  scale_colour_manual(values = method_colours, guide = "none") +
  scale_y_continuous(limits = c(0.5, 1),
                     labels = scales::number_format(accuracy = 0.01)) +
  labs(
    title    = "Downstream AUC (synthetic -> real)",
    subtitle = sprintf(
      "10 seeds; dashed = real-baseline (%.3f)", real_baseline_auc
    ),
    x = NULL, y = "AUC"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(colour = "grey30", size = 10),
    axis.text.x      = element_text(face = "bold", size = 10)
  )

# ---- Panel C: per-variable KS, median across seeds ------------------------

var_summary <- per_var_ks |>
  group_by(method_label, variable) |>
  summarise(
    median_ks = median(ks),
    iqr_lo    = quantile(ks, 0.25),
    iqr_hi    = quantile(ks, 0.75),
    .groups   = "drop"
  ) |>
  mutate(variable = factor(
    variable,
    levels = per_var_ks |> group_by(variable) |>
      summarise(m = median(ks)) |> arrange(m) |> pull(variable)
  ))

pC <- ggplot(var_summary, aes(x = variable, y = median_ks,
                              fill = method_label)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65,
           colour = "grey25", linewidth = 0.2) +
  geom_errorbar(aes(ymin = iqr_lo, ymax = iqr_hi),
                position = position_dodge(width = 0.75),
                width = 0.2, colour = "grey15", linewidth = 0.35) +
  scale_fill_manual(values = method_colours, name = NULL) +
  scale_y_continuous(limits = c(0, NA),
                     labels = scales::number_format(accuracy = 0.01)) +
  coord_flip() +
  labs(
    title    = "Per-variable KS (median across seeds)",
    subtitle = "Lower = marginal better preserved; bars = IQR",
    x = NULL, y = "KS statistic"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 13),
    plot.subtitle    = element_text(colour = "grey30", size = 10),
    axis.text.y      = element_text(size = 8.5),
    legend.position  = "bottom",
    legend.key.size  = unit(0.4, "cm"),
    legend.text      = element_text(size = 9)
  )

# ---- Compose: A (left, full height) + B / C stacked (right) ----------------

combined <- pA + (pB / pC) +
  plot_layout(widths = c(0.5, 0.5)) +
  plot_annotation(
    title = "Three-way comparison: parametric vs bootstrap vs noise synthesis",
    subtitle = sprintf(
      "UCI Wisconsin Breast Cancer (N = %d, %d features); 10 seeds per method",
      N, P
    ),
    caption = paste0(
      "Data: UCI Wisconsin Breast Cancer Diagnostic (Wolberg & Mangasarian ",
      "1990), via mlbench::BreastCancer.  Complete cases only.\n",
      "NN distance ratio per Domingo-Ferrer & Torra (2003); ratio > 1 ",
      "indicates higher privacy. ",
      "Methods: syntheticdata::synthesize(), validate_synthetic(), ",
      "privacy_risk(), model_fidelity()."
    ),
    theme = theme(
      plot.title            = element_text(face = "bold", size = 15),
      plot.subtitle         = element_text(colour = "grey30", size = 12),
      plot.caption          = element_text(colour = "grey35", size = 8.5,
                                           hjust = 0, lineheight = 1.3,
                                           margin = margin(t = 10)),
      plot.caption.position = "plot",
      plot.margin           = margin(10, 18, 10, 10)
    )
  )

# ---- Save ------------------------------------------------------------------

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
out <- "man/figures/privacy_utility_hero.png"
ggsave(out, combined,
       width = 1400, height = 900, units = "px",
       dpi = 150, bg = "white")
sz <- file.info(out)$size
cat("\nSaved:", out, "-", sz, "bytes\n")
stopifnot(sz > 50000)
