# Generates the README hero image for syntheticdata.
#
# Output: man/figures/privacy_utility_hero.png
#
# Runs compare_methods() on a simulated clinical-like dataset and
# plots the three synthesis methods on a 2-D privacy-utility plane:
#   X axis = distributional fidelity (1 - mean KS statistic)
#   Y axis = nearest-neighbor distance ratio (privacy)
# Top-right is best. Ratio = 1 is the privacy floor.

library(syntheticdata)
library(ggplot2)

set.seed(42)
n <- 300
real <- data.frame(
  age     = pmax(30, pmin(90, rnorm(n, 65, 10))),
  sbp     = pmax(80, pmin(200, rnorm(n, 130, 18))),
  bmi     = pmax(15, pmin(45, rnorm(n, 27, 5))),
  glucose = pmax(60, pmin(300, rnorm(n, 95, 25)))
)

cmp <- compare_methods(real, seed = 42)

ks <- cmp[cmp$metric == "ks_statistic_mean", c("method", "value")]
nn <- cmp[cmp$metric == "nn_distance_ratio", c("method", "value")]
names(ks)[2] <- "ks"
names(nn)[2] <- "nn"
d <- merge(ks, nn, by = "method")
d$fidelity <- 1 - d$ks
d$privacy  <- d$nn
d$method_label <- c(
  parametric = "Gaussian copula",
  bootstrap  = "Bootstrap",
  noise      = "Laplace noise"
)[d$method]

x_lo <- max(0, min(d$fidelity) - 0.08)
y_lo <- min(0.5, min(d$privacy) - 0.15)
y_hi <- max(2,  max(d$privacy) + 0.25)

p <- ggplot(d, aes(x = fidelity, y = privacy, colour = method)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1, ymax = Inf,
           fill = "#1B5E20", alpha = 0.05) +
  geom_hline(yintercept = 1, linetype = "dashed",
             colour = "grey50", linewidth = 0.4) +
  geom_point(size = 5.8) +
  geom_text(aes(label = method_label),
            vjust = -1.0, size = 4.1, fontface = "bold",
            show.legend = FALSE) +
  annotate("text", x = x_lo, y = 1,
           label = "Privacy floor (ratio = 1)",
           hjust = 0, vjust = -0.5, size = 3.3, colour = "grey40") +
  scale_colour_manual(
    values = c(parametric = "#1565C0",
               bootstrap  = "#E65100",
               noise      = "#6A1B9A"),
    guide = "none"
  ) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(x_lo, 1)) +
  scale_y_continuous(limits = c(y_lo, y_hi)) +
  labs(
    title    = "Privacy–utility tradeoff across synthesis methods",
    subtitle = sprintf(
      "Simulated clinical-like data (n = %d, 4 numeric variables). Top-right is better.",
      n),
    x = "Distributional fidelity (1 − mean KS statistic)",
    y = "Privacy (nearest-neighbor distance ratio)",
    caption = "Data: simulated normal distributions  |  compare_methods() in syntheticdata"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(colour = "grey30"),
    plot.caption  = element_text(colour = "grey45", size = 9),
    panel.grid.minor = element_blank()
  )

dir.create("man/figures", showWarnings = FALSE, recursive = TRUE)
ggsave("man/figures/privacy_utility_hero.png", p,
       width = 1200, height = 800, units = "px", dpi = 144, bg = "white")

cat("Saved: man/figures/privacy_utility_hero.png\n")
print(d[, c("method", "fidelity", "privacy")])
