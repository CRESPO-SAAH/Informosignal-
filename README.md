# InformoSignal

Nowcasting du volume d'activité du secteur informel au Sénégal à partir d'un proxy numérique (transactions mobile money), avec tableau de bord Shiny et assistant IA intégré.

Projet réalisé dans le cadre du hackathon ANSD 2026.

* **Auteurs** : Hamadou DICKO, YEMELI SAAH Eugène Crespo (ISE 2, ENSAE Pierre Ndiaye)
* **Application en ligne** : https://laminehamadoudicko.shinyapps.io/informosignal/

\---

## Contexte

L'activité informelle représente une part importante de l'économie sénégalaise, mais elle n'est mesurée directement que de façon ponctuelle (enquête ERI-ESI, édition 2017) et sans fréquence infra-annuelle. Les statisticiens disposent donc d'une information tardive sur son évolution.

**Objectif** : produire une série trimestrielle estimée de l'activité du secteur informel, mise à jour dès que de nouvelles données à haute fréquence sont disponibles (nowcasting), et la rendre exploitable via un tableau de bord.

## Méthode

Le calage se fait en deux étapes avec la méthode de Denton (package `tempdisagg`) :

1. **Indicateur trimestriel** : la série annuelle mobile money est désagrégée en trimestres à l'aide de la consommation finale des ménages. L'indicateur hérite ainsi de la dynamique de cette consommation, jugée bon proxy de l'évolution de l'économie sénégalaise.
2. **Calage sur la production** : l'indicateur est calé sur la production annuelle du secteur informel. Le résultat est la **série calée** (production du secteur informel), extrapolée pour les années non observées.

## Application

|Onglet|Contenu|
|-|-|
|**Accueil**|Vue d'ensemble de la série calée et des indicateurs clés|
|**INFORMO AI**|Assistant IA|
|**Indicateur**|Indicateur construit à partir du mobile money|
|**Calage Denton**|Indicateur brut contre série calée|
|**Tableau de bord**|Trois cartes (production, valeur ajoutée, revenu mixte) et graphique d'évolution|

### INFORMO AI

Assistant IA (API Groq, *function calling*) qui permet d'interroger la plateforme en langage naturel. Il peut :

* de relancer le calage ;
* de naviguer dans l'application ;
* de lire les valeurs de la production (série calée), de la valeur ajoutée et du revenu mixte.

La clé API est lue dans la variable d'environnement `GROQ\_API\_KEY`, définie dans `app/.Renviron`. Il s'agit d'une clé dédiée à l'évaluation. Si elle est absente, révoquée ou si le quota est épuisé, seul l'assistant est indisponible. Pour utiliser sa propre clé, modifier `app/.Renviron` :

```
GROQ\_API\_KEY=votre\_cle
```
## Reproductibilité
Ouvrir `informosignal.Rproj` dans Rstudio, puis dans la console R, tapez : 

```r
renv::restore()
```
Cette commande installe automatiquement **toutes les dépendances** avec les versions utilisées au cours du travail et spécifies dans 
`renv.lock`. Cela fait qu'aucune installation manuelle de packages n'est nécessaire. Après il faut redémarrer la session pour pouvoir utiliser ces packages.

(le fichier doit se terminer par un saut de ligne).

## Lancer l'application en local

1. Ouvrir le projet dans RStudio.
2. Installer les packages :

```r
install.packages(c("shiny", "dplyr", "ggplot2", "lubridate", "plotly",
                   "httr2", "janitor", "readxl", "tempdisagg")) (pas nécessaire après le renv::restore())
```

Versions testées : R 4.5.2 avec shiny 1.14.0, dplyr 1.2.1, ggplot2 4.0.3, lubridate 1.9.5, plotly 4.12.1, httr2 1.3.0, janitor 2.2.1, readxl 1.5.0, tempdisagg 1.2.0. Les avertissements « package compilé avec la version R 4.5.3 » au chargement sont sans conséquence.

3. Lancer :

```r
shiny::runApp("app")
```

## Déploiement (shinyapps.io)

Déploiement (shinyapps.io)

L'application en ligne des auteurs est disponible à l'adresse indiquée en tête de ce document. Pour la déployer sous un autre compte :

Disposer d'un compte shinyapps.io (gratuit).
Installer rsconnect :
r
install.packages("rsconnect")
Connecter son compte (une seule fois). Le nom du compte, le token et le secret se trouvent sur shinyapps.io, dans Account > Tokens > Show :
r
rsconnect::setAccountInfo(name   = "nom_de_votre_compte",
                          token  = "TOKEN",
                          secret = "SECRET")
Vérifier que app/.Renviron contient la clé (GROQ_API_KEY=...). Sur shinyapps.io, ce fichier est envoyé avec l'application.
Depuis la racine du projet, déployer en remplaçant nom_de_votre_compte par son propre compte :
r
rsconnect::deployApp(appDir  = "app",
                     appName = "informosignal",
                     account = "nom_de_votre_compte")
L'application est alors disponible à l'adresse https://nom_de_votre_compte.shinyapps.io/informosignal/. Vérifier que l'assistant INFORMO AI répond.