# Publication-standard hero figure for syntheticdata on UCI WDBC.
#
# Data: mlbench::BreastCancer (Wolberg & Mangasarian 1990), 683 cases, 9
#   numeric features.
# Variability: ten seeds per method with fixed RNGkind.
# Output: man/figures/privacy_utility_hero.{png,pdf} @ 600 DPI, 183x120 mm.
# Layout: 3-panel patchwork (top row a|b, bottom row c).

suppressPackageStartupMessages({
  library(syntheticdata)
  library(ggplot2)
  library(patchwork)
  library(ggrepel)
  library(dplyr)
  library(tidyr)
  library(mlbench)
  library(ragg)
  library(systemfonts)
})

# ---- Theme ----------------------------------------------------------------

theme_publication <- function(base_size = 8) {
  theme_classic(base_size = base_size, base_family = "sans") +
    theme(
      plot.title            = element_text(face = "bold", size = rel(1.10),
                                           hjust = 0,
                                           margin = margin(b = 3)),
      plot.subtitle         = element_text(size = rel(0.95),
                                           color = "grey30",
                                           margin = margin(b = 5)),
      plot.caption          = element_text(size = rel(0.85),
                                           color = "grey40",
                                           hjust = 0,
                                           margin = margin(t = 5),
                                           lineheight = 1.15),
      plot.caption.position = "plot",
      plot.title.position   = "plot",
      axis.title            = element_text(size = rel(1.00), color = "black"),
      axis.text             = element_text(size = rel(0.90), color = "black"),
      axis.line             = element_line(linewidth = 0.35, color = "black"),
      axis.ticks            = element_line(linewidth = 0.35, color = "black"),
      panel.grid.major      = element_line(linewidth = 0.25, color = "grey88"),
      panel.grid.minor      = element_blank(),
      legend.title          = element_text(size = rel(1.00), face = "bold"),
      legend.text           = element_text(size = rel(0.90)),
      legend.key.size       = unit(3, "mm"),
      legend.margin         = margin(0, 0, 0, 0),
      legend.background     = element_blank(),
      plot.margin           = margin(4, 6, 4, 6),
      plot.tag              = element_text(face = "bold",
                                           size = rel(1.40),
                                           family = "sans")
    )
}

method_colours <- c(
  "Gaussian copula" = "#0072B2",
  "Bootstrap"       = "#D55E00",
  "Laplace noise"   = "#CC79A7"
)

# ---- Load + clean UCI WDBC ------------------------------------------------

data(BreastCancer, package = "mlbench")
real <- BreastCancer |>
  select(-Id) |>
  filter(complete.cases(across(everything())))

feat_cols <- setdiff(names(real), "Class")
real[feat_cols] <- lapply(real[feat_cols],
                          function(x) as.numeric(as.character(x)))
real$Class <- as.integer(real$Class == "malignant")

N <- nrow(real); P <- length(feat_cols)
cat("UCI BreastCancer cleaned: N=", N, " P=", P, "\n", sep = "")

# ---- Multi-seed comparison with strict per-iteration seeds ---------------

seeds   <- c(42, 1, 7, 17, 99, 123, 555, 2024, 314, 271)
methods <- c("parametric", "bootstrap", "noise")

RNGkind(kind = "Mersenne-Twister", normal.kind = "Inversion",
        sample.kind = "Rejection")

results    <- tibble()
per_var_ks <- tibble()

for (m in methods) {
  for (s in seeds) {
    syn_obj <- synthesize(real, method = m, seed = s)
    if (m %in% c("bootstrap", "noise")) {
      syn_obj$synthetic$Class <- as.integer(syn_obj$synthetic$Class >= 0.5)
    }

    iter_seed <- 10000L * match(m, methods) + s
    set.seed(iter_seed)

    val  <- validate_synthetic(syn_obj)
    priv <- privacy_risk(syn_obj)

    results <- bind_rows(results, tibble(
      method    = m, seed = s,
      fidelity  = 1 - val$value[val$metric == "ks_statistic_mean"],
      privacy   = priv$value[priv$metric == "nn_distance_ratio"],
      corr_diff = val$value[val$metric == "correlation_diff"]
    ))

    for (v in feat_cols) {
      k <- suppressWarnings(
        ks.test(syn_obj$real[[v]], syn_obj$synthetic[[v]])$statistic
      )
      per_var_ks <- bind_rows(per_var_ks, tibble(
        method = m, seed = s, variable = v, ks = unname(k)
      ))
    }
  }
}

# Cap infinite privacy ratios for plotting (documented in caption).
n_inf <- sum(!is.finite(results$privacy))
results$privacy[!is.finite(results$privacy)] <- 6

# Method factor for ordering + colour.
method_map <- c(parametric = "Gaussian copula",
                bootstrap  = "Bootstrap",
                noise      = "Laplace noise")
results$method_label    <- factor(method_map[results$method],
                                  levels = unname(method_map))
per_var_ks$method_label <- factor(method_map[per_var_ks$method],
                                  levels = unname(method_map))

cat("\nSummary by method:\n")
print(results |> group_by(method_label) |>
        summarise(fidelity  = mean(fidelity),
                  privacy   = mean(privacy),
                  corr_diff = mean(corr_diff),
                  .groups   = "drop"))
cat("Infinite privacy ratios (capped at 6):", n_inf, "\n")

# ---- Panel a: privacy-utility plane --------------------------------------

centroids <- results |> group_by(method_label) |>
  summarise(fidelity = mean(fidelity),
            privacy  = mean(privacy),
            .groups  = "drop")

x_lo <- min(results$fidelity) - 0.015
x_hi <- 1.005
y_lo <- 0
y_hi <- 6.5

pA <- ggplot(results, aes(x = fidelity, y = privacy,
                          colour = method_label, fill = method_label)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1, ymax = Inf,
           fill = "#009E73", alpha = 0.03) +
  geom_hline(yintercept = 1, linetype = "dashed",
             colour = "grey45", linewidth = 0.40) +
  stat_ellipse(geom = "polygon", alpha = 0.10, level = 0.95,
               linewidth = 0.35) +
  geom_point(size = 1.4, alpha = 0.85) +
  geom_point(data = centroids, shape = 18,
             size = 3.2, show.legend = FALSE) +
  geom_text_repel(data = centroids,
                  aes(label = method_label, colour = method_label),
                  fontface = "bold", size = 2.7, seed = 1,
                  box.padding = 0.7, point.padding = 0.5,
                  min.segment.length = 0, show.legend = FALSE) +
  annotate("text", x = x_lo + 0.003, y = 1,
           label = "Parity", hjust = 0, vjust = -0.4,
           size = 2.3, colour = "grey30") +
  annotate("text", x = x_hi - 0.002, y = 0.1,
           label = paste0("NN ratio < 1: marginal overlap;",
                          "\nsee privacy_risk() full output"),
           hjust = 1, vjust = 0, size = 1.9, colour = "grey40",
           fontface = "italic", lineheight = 1.1) +
  scale_colour_manual(values = method_colours, guide = "none") +
  scale_fill_manual(values = method_colours, guide = "none") +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(x_lo, x_hi)) +
  coord_cartesian(ylim = c(y_lo, y_hi)) +
  labs(title = "Privacy-utility trade-off",
       x = "Distributional fidelity (1 - mean KS statistic)",
       y = "NN distance ratio") +
  theme_publication()

# ---- Panel b: correlation preservation -----------------------------------

pB <- ggplot(results, aes(x = method_label, y = corr_diff,
                          fill = method_label, colour = method_label)) +
  geom_dotplot(binaxis = "y", stackdir = "center",
               binwidth = 0.0006, dotsize = 1.1,
               alpha = 0.80, stroke = 0.25) +
  stat_summary(fun = median, geom = "crossbar",
               width = 0.50, linewidth = 0.50, fatten = 1,
               colour = "grey15") +
  scale_fill_manual(values = method_colours, guide = "none") +
  scale_colour_manual(values = method_colours, guide = "none") +
  scale_y_continuous(limits = c(0, NA),
                     labels = scales::number_format(accuracy = 0.005)) +
  labs(title = "Multivariate fidelity",
       x = NULL,
       y = "Frobenius ||cor(real) - cor(syn)||") +
  theme_publication() +
  theme(axis.text.x = element_text(face = "bold", size = rel(0.85)))

# ---- Panel c: per-variable KS --------------------------------------------

var_label_map <- c(
  "Cl.thickness"    = "Clump thickness",
  "Cell.size"       = "Uniformity of cell size",
  "Cell.shape"      = "Uniformity of cell shape",
  "Marg.adhesion"   = "Marginal adhesion",
  "Epith.c.size"    = "Single epithelial cell size",
  "Bare.nuclei"     = "Bare nuclei",
  "Bl.cromatin"     = "Bland chromatin",
  "Normal.nucleoli" = "Normal nucleoli",
  "Mitoses"         = "Mitoses"
)
per_var_ks$variable_full <- var_label_map[per_var_ks$variable]

var_summary <- per_var_ks |>
  group_by(method_label, variable_full) |>
  summarise(median_ks = median(ks),
            iqr_lo    = quantile(ks, 0.25),
            iqr_hi    = quantile(ks, 0.75),
            .groups   = "drop") |>
  mutate(variable_full = factor(
    variable_full,
    levels = per_var_ks |> group_by(variable_full) |>
      summarise(m = max(ks)) |> arrange(m) |> pull(variable_full)
  ))

pC <- ggplot(var_summary, aes(y = variable_full, x = median_ks,
                              fill = method_label)) +
  geom_col(position = position_dodge(width = 0.80),
           width = 0.72, colour = "black", linewidth = 0.25) +
  geom_errorbarh(aes(xmin = iqr_lo, xmax = iqr_hi),
                 position = position_dodge(width = 0.80),
                 height = 0.25, colour = "grey15", linewidth = 0.35) +
  scale_fill_manual(values = method_colours, name = NULL) +
  scale_x_continuous(limits = c(0, NA),
                     breaks = seq(0, 1, 0.1),
                     labels = scales::number_format(accuracy = 0.01)) +
  labs(title = "Per-feature distributional similarity",
       x = "Kolmogorov-Smirnov statistic",
       y = NULL) +
  theme_publication() +
  theme(
    legend.position      = "bottom",
    legend.direction     = "horizontal",
    legend.key.size      = unit(2.6, "mm"),
    legend.margin        = margin(t = 0, b = 0)
  )

# ---- Compose --------------------------------------------------------------

combined <- ((pA + pB) / pC) +
  plot_layout(heights = c(3, 2)) +
  plot_annotation(
    title    = "Privacy-utility evaluation of synthetic data generation",
    subtitle = sprintf(
      "UCI Wisconsin Breast Cancer (N = %d, %d features); 10 seeds per method.",
      N, P
    ),
    caption  = paste0(
      "Panel a: one point per seed; 95% confidence ellipses.\n",
      "NN distance ratio = median d(syn->real) / median d(real->real'); ",
      "values > 1 indicate synthetic farther from real than real-from-real.\n",
      "Panel b: Frobenius norm of real-vs-synthetic correlation matrix; ",
      "lower = better multivariate preservation.\n",
      "Panel c: KS per feature, median and IQR across 10 seeds.\n",
      "Data: mlbench::BreastCancer (Wolberg & Mangasarian 1990). ",
      "NN ratio: Domingo-Ferrer & Torra (2003)."
    ),
    tag_levels = "a"
  ) &
  theme(
    plot.tag     = element_text(face = "bold", size = 11, family = "sans"),
    plot.caption = element_text(hjust = 0, color = "grey40",
                                size = rel(0.85), lineheight = 1.15,
                                margin = margin(t = 5)),
    plot.caption.position = "plot"
  )

# ---- Save ------------------------------------------------------------------

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)

ggsave(
  filename = "man/figures/privacy_utility_hero.png",
  plot     = combined,
  device   = ragg::agg_png,
  width    = 183, height = 120, units = "mm",
  res      = 600, scaling = 1, bg = "white"
)
cat("\nPNG saved:", file.info("man/figures/privacy_utility_hero.png")$size,
    "bytes\n")

ggsave(
  filename = "man/figures/privacy_utility_hero.pdf",
  plot     = combined,
  device   = cairo_pdf,
  width    = 183, height = 120, units = "mm"
)
cat("PDF saved:", file.info("man/figures/privacy_utility_hero.pdf")$size,
    "bytes\n")

stopifnot(file.info("man/figures/privacy_utility_hero.png")$size > 100000)
