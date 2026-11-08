library(tempdisagg)

# Série annuelle -> ts, sans les NA de début/fin (ils seront extrapolés)
annuel_vers_ts <- function(annee, valeur) {
  ok <- which(!is.na(valeur))
  i <- min(ok); j <- max(ok)
  ts(valeur[i:j], start = annee[i], frequency = 1)
}

# Un calage : indicateur trimestriel (ts) + repère annuel (ts)
calage_denton <- function(indicateur, repere, conversion = "sum",
                          methode = "denton-cholette") {
  modele <- td(repere ~ 0 + indicateur, method = methode, conversion = conversion)
  predict(modele)
}

# Les deux étapes enchaînées
calage_deux_etapes <- function(trimestriel, annuel, annee_debut = NULL) {
  
  if (!is.null(annee_debut)) {
    annuel      <- annuel[annuel$annee >= annee_debut, ]
    trimestriel <- trimestriel[as.integer(format(trimestriel$trimestre, "%Y")) >= annee_debut, ]
  }
  
  debut <- c(as.integer(format(min(trimestriel$trimestre), "%Y")),
             as.integer(format(min(trimestriel$trimestre), "%m")) %/% 3 + 1)
  conso <- ts(trimestriel$consommation_trimest, start = debut, frequency = 4)
  
  mm_ts   <- annuel_vers_ts(annuel$annee, annuel$mobile_money)
  prod_ts <- annuel_vers_ts(annuel$annee, annuel$production)
  
  indicateur <- calage_denton(conso, mm_ts, conversion = "average")               # étape 1
  serie_calee       <- calage_denton(indicateur, prod_ts) # étape 2
  
  trimestriel$indicateur <- as.numeric(indicateur)
  trimestriel$serie_calee       <- as.numeric(serie_calee)
  trimestriel
}
