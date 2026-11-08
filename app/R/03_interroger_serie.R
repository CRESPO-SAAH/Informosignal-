interroger_serie <- function(serie, agregat = "prod", annee_debut = NULL, annee_fin = annee_debut,
                             trimestre = NULL, derniers = 4) {
  if (!all(agregat %in% c("prod", "va", "rm"))) {
    stop("agregat doit être parmi 'prod', 'va', 'rm'")
  }
  
  serie <- serie[order(serie$trimestre), ]
  
  res_complet <- data.frame(annee = serie$annee, trimestre = serie$trimestre)
  
  for (ag in agregat) {
    v <- serie[[ag]]
    res_complet[[ag]] <- round(v, 1)
    res_complet[[paste0("variation_", ag)]] <- round(100 * (v / c(NA, v[-length(v)]) - 1), 1)
  }
  
  if (is.null(annee_debut)) return(tail(res_complet, derniers))
  
  res <- res_complet[res_complet$annee >= annee_debut & res_complet$annee <= annee_fin, ]
  if (!is.null(trimestre)) res <- res[res$trimestre == trimestre, ]
  res
}