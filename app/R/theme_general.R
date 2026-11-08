COL_ACCENT <- "#E8A045"
COL_FOND   <- "#FAF7F2"
COL_GRILLE <- "#E8E2D9"

library(lubridate)

COL_TRIMESTRE <- c("T1" = "#4E79A7", "T2" = "#F28E2B", "T3" = "#59A14F", "T4" = "#E15759")

ajouter_trimestre_label <- function(df) {
  df$trimestre_label <- factor(paste0("T", quarter(df$trimestre)), levels = c("T1", "T2", "T3", "T4"))
  df
}

theme_general <- function(base_size = 12) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      plot.background    = element_rect(fill = COL_FOND, color = NA),
      panel.background   = element_rect(fill = COL_FOND, color = NA),
      panel.grid.major   = element_line(color = COL_GRILLE, linewidth = 0.45),
      panel.grid.minor   = element_blank(),
      plot.title         = element_text(face = "bold", size = base_size + 1,
                                        color = "#2E2319", margin = margin(b = 4)),
      plot.subtitle      = element_text(color = "#6B5C4A", size = base_size - 1,
                                        margin = margin(b = 8)),
      plot.caption       = element_text(color = "#9C8B7A", size = base_size - 3,
                                        hjust = 0, margin = margin(t = 6)),
      axis.title         = element_text(color = "#4A3C2F", size = base_size - 1),
      axis.text          = element_text(color = "#5C4D3E"),
      legend.background  = element_rect(fill = COL_FOND, color = NA),
      legend.key         = element_rect(fill = COL_FOND, color = NA),
      strip.background   = element_rect(fill = "#EDE6DC", color = NA),
      strip.text         = element_text(face = "bold", color = "#2E2319")
    )
}

PALETTE_CATEGORIELLE <- c(
  "#EAAB5A", "#A78E7F", "#C76A43", "#6E8965", "#B8733A",
  "#7A5C4E", "#D4895B", "#4F6B45", "#C4956A", "#8B6355",
  "#E09B4A", "#5C7A52", "#A0614F", "#3D5C38", "#B85A4A"
)
