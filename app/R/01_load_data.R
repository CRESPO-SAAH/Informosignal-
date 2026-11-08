load_data <- function(processed_dir = "data/processed") {
  f_ann <- file.path(processed_dir, "annuel.rds")
  f_tri <- file.path(processed_dir, "trimestriel.rds")
  
  if (!file.exists(f_ann) || !file.exists(f_tri)) {
    message("Pas de données réelles -> utilisation des données fictives.")
    return(generate_mock_data())
  }
  
  list(
    annuel      = readRDS(f_ann),
    trimestriel = readRDS(f_tri)
  )
}
