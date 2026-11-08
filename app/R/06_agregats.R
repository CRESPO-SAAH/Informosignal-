# =============================================================================
# 06_agregats.R : agrégats dérivés de la série calée
# =============================================================================
   
TAUX_VA   <- 0.45
TAUX_RM   <- 0.88


predire_taux_VA <- function(hist,
                            methode = c("tendance", "moyenne", "dernier"),
                            n = 1) {
  methode <- match.arg(methode)
  
  b <- hist |>
    dplyr::select(annee, production, valeur_ajoutee) |>
    dplyr::filter(!is.na(annee), !is.na(production), !is.na(valeur_ajoutee)) |>
    dplyr::arrange(annee) |>
    dplyr::mutate(taux_VA = valeur_ajoutee / production)
  
  annees_futures <- max(b$annee) + seq_len(n)
  
  prevus <- switch(
    methode,
    tendance = as.numeric(predict(
      lm(taux_VA ~ annee, data = b),
      newdata = data.frame(annee = annees_futures)
    )),
    moyenne = rep(mean(b$taux_VA), n),
    dernier = rep(tail(b$taux_VA, 1), n)
  )
  
  prevus <- pmin(pmax(prevus, 0), 1)
  
  data.frame(
    annee = c(b$annee, annees_futures),
    taux_VA = c(b$taux_VA, prevus)
  )
}


deriver_agregats <- function(serie, taux_va = TAUX_VA, taux_rm = TAUX_RM) {
  
  serie <- serie |>
    dplyr::mutate(annee = as.integer(format(trimestre, "%Y"))) |>
    dplyr::left_join(taux_va, by = "annee")
  
  mois <- as.integer(format(serie$trimestre, "%m"))
  s <- data.frame(
    annee     = serie$annee,
    trimestre = (mois - 1) %/% 3 + 1,
    prod      = serie$serie_calee
  )
  s$va <- s$prod * serie$taux_VA   # chaque trimestre × taux de son année
  s$rm <- s$va   * taux_rm
  s
}
