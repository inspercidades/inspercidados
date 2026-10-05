# Hex sticker ----
#
# Redraws the Insper Cidades symbol: five dots on a triangular lattice, joined
# in a chain (top, middle-left, middle-right, bottom-right, bottom-left).
# Writes man/figures/logo.png.

library(ggplot2)

insper_dark <- "#0E171D"
dot_color <- "#f1ece7"

sysfonts::font_add_google("Inter", "Inter", regular.wt = 600)
showtext::showtext_auto()

# Symbol ----

h <- sqrt(3) / 2

dots <- data.frame(
  id = c("top", "mid_left", "mid_right", "bottom_left", "bottom_right"),
  x = c(0.5, 0, 1, 0.5, 1.5),
  y = c(2 * h, h, h, 0, 0)
)

links <- data.frame(
  from = c("top", "mid_left", "mid_right", "bottom_right"),
  to = c("mid_left", "mid_right", "bottom_right", "bottom_left")
)
links$x <- dots$x[match(links$from, dots$id)]
links$y <- dots$y[match(links$from, dots$id)]
links$xend <- dots$x[match(links$to, dots$id)]
links$yend <- dots$y[match(links$to, dots$id)]

# Point and line sizes are in mm, tuned for the fixed sticker size below
symbol <- ggplot() +
  geom_segment(
    data = links,
    aes(x = x, y = y, xend = xend, yend = yend),
    linewidth = 4.8,
    color = dot_color
  ) +
  geom_point(data = dots, aes(x = x, y = y), size = 10.5, color = dot_color) +
  coord_fixed(xlim = c(-0.5, 2), ylim = c(-0.5, 2 * h + 0.5)) +
  theme_void()

# Sticker ----

hexSticker::sticker(
  symbol,
  package = "inspercidados",
  p_family = "Inter",
  p_size = 16,
  p_y = 0.6,
  p_color = dot_color,
  s_x = 1.075,
  s_y = 1.25,
  s_width = 1.2,
  s_height = 1.2,
  h_fill = insper_dark,
  h_color = dot_color,
  dpi = 300,
  filename = "man/figures/logo.png"
)
