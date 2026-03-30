devtools::load_all(".", quiet = TRUE)
library(ggplot2)
library(patchwork)

## Use R's built-in iris dataset - real data published by
## Fisher RA (1936). Annals of Eugenics 7:179-188.
real <- iris[, c("Sepal.Length", "Sepal.Width", "Petal.Length",
                  "Petal.Width", "Species")]

syn_obj <- synthesize(real, method = "parametric", seed = 2024)
val <- validate_synthetic(syn_obj)

cat("Validation:\n"); print(val)

od <- "man/figures"
pal <- c(Real = "#0072B2", Synthetic = "#D55E00")

## ============================================================
## Fig 1: Distributional fidelity - paired density overlays
## ============================================================
num_cols <- c("Sepal.Length", "Sepal.Width",
              "Petal.Length", "Petal.Width")

density_df <- do.call(rbind, lapply(num_cols, function(col) {
    data.frame(
        variable = col,
        value = c(real[[col]], syn_obj$synthetic[[col]]),
        source = rep(c("Real", "Synthetic"),
                      c(nrow(real), nrow(syn_obj$synthetic))),
        stringsAsFactors = FALSE)
}))

pa <- ggplot(density_df, aes(x = value, fill = source)) +
    geom_density(alpha = 0.45, color = NA) +
    facet_wrap(~ variable, scales = "free", nrow = 1) +
    scale_fill_manual(values = pal, name = NULL) +
    labs(x = NULL, y = "Density",
         title = expression(bold("a"))) +
    theme_classic(base_size = 8, base_family = "sans") +
    theme(legend.position = c(0.92, 0.85),
          legend.background = element_blank(),
          legend.key.size = unit(8, "pt"),
          strip.text = element_text(size = 6.5, face = "bold"),
          panel.grid = element_blank())

## ============================================================
## Fig 1b: Correlation preservation
## ============================================================
cor_real <- cor(real[, num_cols])
cor_syn <- cor(syn_obj$synthetic[, num_cols])

cor_df <- data.frame(
    real_cor = as.vector(cor_real[lower.tri(cor_real)]),
    syn_cor = as.vector(cor_syn[lower.tri(cor_syn)]),
    stringsAsFactors = FALSE)

pb <- ggplot(cor_df, aes(x = real_cor, y = syn_cor)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                color = "#999999", linewidth = 0.3) +
    geom_point(size = 2.5, color = "#009E73", alpha = 0.8) +
    annotate("text", x = -0.2, y = 0.9,
             label = paste0("Frobenius diff = ",
                 round(sqrt(sum((cor_real - cor_syn)^2)) /
                       length(cor_real), 4)),
             size = 2.5, hjust = 0) +
    coord_equal(xlim = c(-0.5, 1), ylim = c(-0.5, 1)) +
    labs(x = "Real correlation", y = "Synthetic correlation",
         title = expression(bold("b"))) +
    theme_classic(base_size = 8, base_family = "sans") +
    theme(panel.grid = element_blank())

## ============================================================
## Fig 1c: Privacy - nearest-neighbor distance
## ============================================================
## Use validation result
privacy_ratio <- val$value[val$metric == "nn_distance_ratio"]
disc_auc <- val$value[val$metric == "discriminative_auc"]
ks_mean <- val$value[val$metric == "ks_statistic_mean"]

metric_df <- data.frame(
    metric = c("KS statistic", "Disc. AUC", "NN dist ratio"),
    value = c(ks_mean, disc_auc, privacy_ratio),
    target = c(0, 0.5, 1),
    good = c("< 0.1", "~ 0.5", "> 1.0"),
    color = c(
        ifelse(ks_mean < 0.1, "#009E73", "#D55E00"),
        ifelse(abs(disc_auc - 0.5) < 0.05, "#009E73", "#D55E00"),
        ifelse(privacy_ratio > 1, "#009E73", "#D55E00")),
    stringsAsFactors = FALSE)

pc <- ggplot(metric_df, aes(x = metric, y = value)) +
    geom_col(fill = metric_df$color, width = 0.5, alpha = 0.85) +
    geom_text(aes(label = sprintf("%.3f", value)),
              vjust = -0.3, size = 2.5) +
    geom_hline(data = metric_df[metric_df$metric == "Disc. AUC", ],
               aes(yintercept = 0.5), linetype = "dashed",
               color = "#999999", linewidth = 0.3) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
    labs(x = NULL, y = "Value",
         title = expression(bold("c"))) +
    theme_classic(base_size = 8, base_family = "sans") +
    theme(panel.grid = element_blank())

fig1 <- pa / (pb | pc)
ggsave(file.path(od, "fig1_synthetic_validation.png"),
       fig1, width = 183, height = 110, units = "mm",
       dpi = 300, bg = "white")
cat("fig1 saved\n")
