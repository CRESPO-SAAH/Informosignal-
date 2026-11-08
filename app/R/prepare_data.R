library(readxl)
library(dplyr)
library(janitor)

# --- Chemins (relatifs à la racine du projet) ---
fichier     <- "data/raw/data.xlsx"
dossier_out <- "data/processed"
dir.create(dossier_out, recursive = TRUE, showWarnings = FALSE)

# --- Lecture : feuille annuelle ---
annuel <- read_excel(fichier, sheet = "annuel") |>
  clean_names() |>
  rename(annee = dates) |>
  mutate(annee = as.integer(annee)) |>
  select(annee, mobile_money, production, valeur_ajoutee)

# --- Lecture : feuille trimestrielle ---
trimestriel <- read_excel(fichier, sheet = "trimestriel") |>
  clean_names() |>
  mutate(trimestre = as.Date(trimestre))

# --- Sauvegarde ---
saveRDS(annuel,      file.path(dossier_out, "annuel.rds"))
saveRDS(trimestriel, file.path(dossier_out, "trimestriel.rds"))
message("Données sauvegardées dans ", dossier_out)