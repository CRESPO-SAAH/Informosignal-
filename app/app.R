if (file.exists(".Renviron")) readRenviron(".Renviron") # Charge la clé API

library(shiny)
library(ggplot2)
library(lubridate)
library(plotly)

#-------------------------------------------------------------------------------------------------

source("R/utils_mock_data.R")
source("R/theme_general.R")

#-------------------------------------------------------------------------------------------------

source("R/01_load_data.R")
source("R/02_denton.R")
source("R/03_interroger_serie.R")
source("R/04_LLM.R")
source("R/05_ui_helpers.R")
source("R/06_agregats.R")

#-------------------------------------------------------------------------------------------------

ui <- fluidPage(
  style_cartes(),
  titlePanel("INFORMOSIGNAL : Nowcasting activité informelle"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("annee_repere", "Année repère", value = 2017),
      width = 3
      
      #Code pour le remplissage des données depuis la plateforme
      
        #tags$hr(style = "border-top: 2px solid #8a8f98; margin: 25px 0;"),
        #h4("Prolonger les séries"),
        
        #h5("Production du secteur informel (annuelle)"),
        #div(style = "font-size:16px; font-weight:bold; color:#1f4e79; margin-bottom:8px;",
          #textOutput("annee_a_saisir")),
      #numericInput("maj_prod", "Production", value = NA, min = 0),
      #actionButton("ajouter_annuel", "Enregistrer la production"),
      
      #hr(),
      
      #h5("Consommation finale des ménages (trimestrielle)"),
      #div(style = "font-size:16px; font-weight:bold; color:#1f4e79; margin-bottom:8px;",
          #textOutput("trim_a_saisir")),
      #numericInput("maj_conso", "Consommation finale", value = NA, min = 0),
      #actionButton("ajouter_trim", "Enregistrer le trimestre")
    ),
    
    mainPanel(
      tabsetPanel(id = "onglets",
        tabPanel("Accueil",
                  uiOutput("kpi_trimestrielle"),
                   plotly::plotlyOutput("plot_calee", width = "100%", height = "500px")
        ),
        tabPanel("INFORMO AI",
                 br(),
                 textAreaInput("prompt_utilisateur", "Salut, que souhaitez-vous savoir?",
                               placeholder = "Ecrivez un message ici....",
                               width = "100%", rows = 3),
                 actionButton("envoyer_prompt", "Envoyer", class = "btn-primary"),
                 hr(),
                 verbatimTextOutput("reponse_assistant")
        ),
        tabPanel("Indicateur", plotly::plotlyOutput("plot_brut", width = "100%", height = "500px")),
        tabPanel("Calage Denton",
                 plotly::plotlyOutput("plot_denton", width = "100%", height = "450px"),
                 hr(),
                 br(),
                 plotly::plotlyOutput("plot_ratio_ri", width = "100%", height = "350px")
        ),
        tabPanel("Tableau de bord",
                 fluidRow(
                   column(3, selectInput('annee_tdb', 'Année', choices = NULL)),
                   column(4, radioButtons('pas_tdb', 'Pas de temps', choices = c("trimestriel" = "tri", "annuel" = "ann"), inline = TRUE))
                 ),
                 uiOutput("cartes_kpi"),
                 plotly::plotlyOutput('graph_evolution')
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # ============================================================
  # DONNÉES ET CALCULS PARTAGÉS (utilisés par plusieurs onglets)
  # ============================================================
  
  #base    <- reactiveVal(load_data())  
  #donnees <- reactive(base())
  
  donnees <- reactive({
    load_data()
  })
  
  calage <- reactive({
    d <- donnees()
    annee <- as.integer(input$annee_repere)
    depuis <- d$annuel[d$annuel$annee >= annee, ]
    
    validate(
      need(annee %in% d$annuel$annee,
           "L'année de départ doit figurer dans la base annuelle."),
      need(any(!is.na(depuis$mobile_money)),
           "Aucune valeur de mobile money observée à partir de cette année."),
      need(any(!is.na(depuis$production)),
           "Aucune valeur de production observée à partir de cette année.")
    )
    
    calage_deux_etapes(d$trimestriel, d$annuel, annee_debut = input$annee_repere)
  })
  # Agrégats dérivés, recalculés automatiquement quand le calage change

  taux <- reactive({
    predire_taux_VA(donnees()$annuel, methode = "tendance", n = (length(calage()$serie_calee)-length(donnees()$annuel$production)))
  })
  agregats <- reactive({
    deriver_agregats(calage(), taux_va = taux())
  })
  
  # ============================================================
  # ONGLET : Barre latérale
  # ============================================================
  
  #lib_trim <- function(d) paste0(format(d, "%Y"), " T", (as.integer(format(d, "%m")) - 1) %/% 3 + 1)
  
  # --- Ce qu'il faut renseigner ---
  #prochain_trim <- reactive({
    #seq(max(donnees()$trimestriel$trimestre), by = "3 months", length.out = 2)[2]
  #})
  
  #prochaine_annee <- reactive({
    #a <- donnees()$annuel
    #max(a$annee) + 1
  #})
  
  #output$trim_a_saisir <- renderText({
    #paste0("Trimestre à renseigner : ", lib_trim(prochain_trim()),
          # "  (dernier disponible : ", lib_trim(max(donnees()$trimestriel$trimestre)), ")")
  #})
  
  #output$annee_a_saisir <- renderText({
    #paste0("Année à renseigner : ", prochaine_annee())
  #})
  
  # --- Enregistrement de la consommation ---
  #observeEvent(input$ajouter_trim, {
    #if (!is.finite(input$maj_conso)) {
      #return(showNotification("Saisis une valeur de consommation.", type = "error"))
    #}
    #d    <- donnees()
    #date <- prochain_trim()
    #d$trimestriel <- dplyr::bind_rows(
      #d$trimestriel,
      #tibble::tibble(trimestre = date, consommation_trimest = input$maj_conso)
    #)
    #donnees(d)
    #updateNumericInput(session, "maj_conso", value = NA)
    #showNotification(paste0(lib_trim(date), " enregistré."), type = "message")
  #})
  
  # ============================================================
  # ONGLET : Accueil
  # ============================================================
  
  # Cartes des dernières valeurs trimestrielles (production, VA, revenu mixte)
  output$kpi_trimestrielle <- renderUI({
    a <- agregats()
    valeurs_trimestrielles <- a[nrow(a),]
    fmt <- function(x) format(round(x, 1), nsmall = 1, big.mark = " ", decimal.mark = ",")
    detail <- paste0("Année ",valeurs_trimestrielles$annee,"  T", valeurs_trimestrielles$trimestre)
    
    fluidRow(
      column(3, carte_kpi("Production",         fmt(valeurs_trimestrielles$prod), detail, "#0f8b8d")),
      column(3, carte_kpi("Valeur ajoutée",     fmt(valeurs_trimestrielles$va),   detail, "#8e3b6b")),
      column(3, carte_kpi("Revenu mixte",       fmt(valeurs_trimestrielles$rm),   detail, "#d98e1f"))
    )
  })
  
  # Graphique de la série calée
  output$plot_calee <- plotly::renderPlotly({
    dat <- calage()
    mois <- as.integer(format(dat$trimestre, "%m"))
    dat$etiquette <- paste0("T", (mois - 1) %/% 3 + 1, " ", format(dat$trimestre, "%Y"))
    
    p <- ggplot(dat, aes(x = trimestre, y = serie_calee, group = 1,
                         text = paste0(etiquette, " : ", round(serie_calee, 1)))) +
      geom_line(color = PALETTE_CATEGORIELLE[1], linewidth = 1) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                   expand = expansion(mult = c(0.02, 0.02))) +
      labs(title = "Evolution trimestrielle de la Production Informelle", x = NULL, y = NULL) +
      theme_general() +
      theme(legend.position = "none",
            plot.background  = element_rect(fill = "white", colour = NA),
            panel.background = element_rect(fill = "white", colour = NA))
    
    plotly::ggplotly(p, tooltip = "text") |>
      plotly::layout(hovermode = "x unified")
  })
  
  
  # ============================================================
  # ONGLET : Assistant IA
  # ============================================================
  
  # Outils que le modèle peut appeler 
  outils_disponibles <- list(
    list(
      type = "function",
      `function` = list(
        name = "interroger_serie",
        description = paste0(
          "Lit un agrégat économique du secteur informel. La série calée du dashboard EST ",
          "directement la production informelle (prod) ; les 2 autres agrégats en sont dérivés en ",
          "chaîne par des taux :valeur ajoutée (va) et revenu mixte (rm). ",
          "Renvoie, pour l'agrégat demandé, le niveau et la variation en % par rapport au ",
          "trimestre précédent. ",
          "Ne donne PAS l'indicateur brut mobile money, ni la corrélation, ni le ratio RI. ",
          "À utiliser pour toute question sur le niveau ou l'évolution de l'un de ces 3 agrégats. ",
          "Sans argument, renvoie la production des derniers trimestres disponibles."
        ),
parameters = list(
  type = "object",
  properties = list(
    agregat = list(
      type = "array",
      items = list(
        type = "string",
        enum = list("prod", "va", "rm")
      ),
      description = "Un ou plusieurs agrégats demandés : prod (production), va (valeur ajoutée), rm (revenu mixte). Défaut : prod."
    ),
    annee_debut = list(
      type = "integer",
      description = "Première année de la période demandée (ex. 2019). Omettre pour obtenir les derniers trimestres."
    ),
    annee_fin = list(
      type = "integer",
      description = "Dernière année de la période. Omettre si une seule année est demandée."
    ),
    trimestre = list(
      type = "integer",
      enum = list(1, 2, 3, 4),
      description = "Numéro du trimestre (1 à 4) pour cibler un trimestre précis. Omettre pour tous les trimestres."
    ),
    derniers = list(
      type = "integer",
      description = "Nombre de derniers trimestres à renvoyer quand aucune année n'est donnée (défaut : 4)."
    )
  )
)
      )
    ),
    list(
      type = "function",
      "function" = list(
        name = "changer_onglet",
        description = "Affiche un onglet précis du dashboard",
        parameters = list(
          type = "object",
          properties = list(
            nom_onglet = list(
              type = "string",
              description = "Nom exact de l'onglet",
              enum = list("Accueil", "INFORMO AI", "Indicateur", "Calage Denton", "Tableau de bord")
            )
          ),
          required = list("nom_onglet")
        )
      )
    ),
list(
  type = "function",
  "function" = list(
    name = "recalculer_calage",
    description = paste(
      "Relance le calage en deux étapes (consommation des ménages -> mobile money,",
      "puis indicateur -> production du secteur informel) à partir d'une année de départ.",
      "L'année doit figurer dans la base annuelle."
    ),
    parameters = list(
      type = "object",
      properties = list(
        annee_repere = list(
          type = "integer",
          description = "Année de départ du calage (première année de la période utilisée)"
        )
      ),
      required = list("annee_repere")
    )
  )
)
  )
  
  # Envoi du prompt : contexte, premier appel, exécution de l'outil, second appel
  
  historique <- reactiveVal(character(0))
  historique_llm <- reactiveVal(list())
  observeEvent(input$envoyer_prompt, {
    # --- Contexte dynamique ---
    cal <- calage()
    mois <- as.integer(format(max(cal$trimestre), "%m"))
    dernier <- paste0("T", (mois - 1) %/% 3 + 1, " ", format(max(cal$trimestre), "%Y"))
    
    s <- agregats()
    
    contexte <- paste0(
      "Tu es l'assistant du dashboard InformoSignal, qui présente une estimation ",
      "trimestrielle de l'activité économique informelle au Sénégal. ",
      "La série calée du dashboard EST directement la production (CA) du secteur ",
      "informelle ; les 2 autres agrégats affichés — valeur ajoutée et revenu ",
      "mixte — en sont dérivés en chaîne à partir de la prod, via des taux (prod → valeur ajoutée ",
      " → revenu mixte, chacun calculé à partir du précédent). ",
      "La série affichée couvre jusqu'à ", dernier, ", dernier trimestre disponible. ",
      "Sans précision de l'utilisateur, 'ce trimestre' ou 'le dernier trimestre' ",
      "désigne ", dernier, ". Sans précision sur l'agrégat, suppose que l'utilisateur ",
      "parle de la production. ",
      "Repère de calage actuel : ", input$valeur_repere, " en ", input$annee_repere, ". ",
      "Pour toute valeur chiffrée, appelle l'outil interroger_serie ; n'invente jamais de chiffre. ",
      "Si la question porte sur autre chose que ces 3 agrégats (Indicateur, corrélation, ratio), ",
      "dis clairement que tu ne peux pas y accéder pour l'instant. ",
      "Indique toujours la période et l'agrégat dont tu parles, et réponds en français. ",
      "Ne mentionne le repère de calage ou le dashboard que si l'utilisateur le demande. ",
      "N'utilise ni tableau ni mise en forme markdown : écris en phrases simples. "
    )
    
    # --- Premier appel ---
    prompt_actuel <- input$prompt_utilisateur
    messages <- c(
        list(list(role = "system", content = contexte)),
        historique_llm(),
        list(list(role = "user",   content = input$prompt_utilisateur))
    )
    message_llm <- appeler_LLM(messages, outils_disponibles)
    
    if (!is.null(message_llm$tool_calls)) {
      appel_outil <- message_llm$tool_calls[[1]]
      appel <- appel_outil$`function`
      args <- jsonlite::fromJSON(appel$arguments)
      
      if (appel$name == "recalculer_calage") {
        annee  <- as.integer(args$annee_repere)
        annuel <- donnees()$annuel
        depuis <- annuel[annuel$annee >= annee, ]
        
        valide <- annee %in% annuel$annee &&
          any(!is.na(depuis$mobile_money)) &&
          any(!is.na(depuis$production))
        
        if (!valide) {
          reponse_text <- paste0(
            "Année de départ impossible : ", annee, ". Années disponibles : ",
            min(annuel$annee), " à ", max(annuel$annee),
            " (il faut au moins un repère observé de mobile money et de production à partir de cette année)."
          )
        } else {
          updateSelectInput(session, "annee_repere", selected = annee)
          reponse_text <- paste0("Calage relancé à partir de ", annee, ".")
        }
      }else if (appel$name == "changer_onglet") {
        updateTabsetPanel(session, "onglets", selected = args$nom_onglet)
        reponse_text <- paste0("Affichage de l'onglet : ", args$nom_onglet)
        
      } else if (appel$name == "interroger_serie") {
        # 1. R exécute la fonction avec les arguments choisis par le modèle
        resultat <- do.call(interroger_serie, c(list(serie = s), args))
        
        # 2. On complète l'historique : demande du modèle + résultat de l'outil
        messages <- c(messages, list(
          message_llm,
          list(
            role = "tool",
            tool_call_id = appel_outil$id,
            content = as.character(jsonlite::toJSON(resultat, auto_unbox = TRUE, na = "null"))
          )
        ))
        
        # 3. Second appel : le modèle rédige la réponse avec les vrais chiffres
        reponse_finale <- appeler_LLM(messages, outils_disponibles)
        reponse_text <- reponse_finale$content
      }
      
    } else {
          reponse_text <- message_llm$content
    }
    
    historique_llm(c(
      historique_llm(),
      list(list(role = "user", content = prompt_actuel)),
      list(list(role = "assistant", content = reponse_text))
    ))
    
    historique(c(
      historique(),
      paste0("Vous : ", prompt_actuel),
      paste0("Assistant : ", reponse_text),
      ""
    ))
    
    output$reponse_assistant <- renderText({
      paste(historique(), collapse = "\n")
    })
    
    updateTextAreaInput(session, "prompt_utilisateur", value = "")
  })

  
  
  
  # ============================================================
  # ONGLET : Indicateur
  # ============================================================
  
  output$plot_brut <- plotly::renderPlotly({
    dat <- calage()
    mois <- as.integer(format(dat$trimestre, "%m"))
    dat$etiquette <- paste0("T", (mois - 1) %/% 3 + 1, " ", format(dat$trimestre, "%Y"))
    
    p <- ggplot(dat, aes(x = trimestre, y = indicateur, group = 1,
                         text = paste0(etiquette, " : ", round(indicateur, 1)))) +
      geom_line(color = PALETTE_CATEGORIELLE[1], linewidth = 1) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                   expand = expansion(mult = c(0.02, 0.02))) +
      labs(title = "Indicateur basé sur les mobiles money", x = NULL, y = NULL) +
      theme_general() +
      theme(legend.position = "none",
            plot.background  = element_rect(fill = "white", colour = NA),
            panel.background = element_rect(fill = "white", colour = NA))
    
    plotly::ggplotly(p, tooltip = "text") |>
      plotly::layout(hovermode = "x unified")
  })
  
  
  # ============================================================
  # ONGLET : Calage Denton
  # ============================================================
  
  # Indicateur brut vs série calée (légende cliquable)
  output$plot_denton <- plotly::renderPlotly({
    dat <- calage()
    mois <- as.integer(format(dat$trimestre, "%m"))
    dat$etiquette <- paste0("T", (mois - 1) %/% 3 + 1, " ", format(dat$trimestre, "%Y"))
    
    noms <- c("Indicateur", "Série calée")
    long <- data.frame(
      trimestre = rep(dat$trimestre, 2),
      etiquette = rep(dat$etiquette, 2),
      serie     = factor(rep(noms, each = nrow(dat)), levels = noms),
      valeur    = c(dat$indicateur, dat$serie_calee)
    )
    
    p <- ggplot(long, aes(x = trimestre, y = valeur, color = serie, group = serie,
                          text = paste0(etiquette, " – ", serie, " : ", round(valeur, 1)))) +
      geom_line(linewidth = 1) +
      scale_color_manual(values = c("Indicateur" = PALETTE_CATEGORIELLE[1],
                                    "Série calée"     = PALETTE_CATEGORIELLE[3])) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                   expand = expansion(mult = c(0.02, 0.02))) +
      labs(title = "Signal de l'indicateur sur l'évolution de la production", x = NULL, y = NULL, color = NULL) +
      theme_general() +
      theme(plot.background  = element_rect(fill = "white", colour = NA),
            panel.background = element_rect(fill = "white", colour = NA),
            legend.background = element_rect(fill = "white", colour = NA))
    
    g <- plotly::ggplotly(p, tooltip = "text")
    
    # Rattache la courbe "Indicateur" à un second axe Y (à droite)
    for (i in seq_along(g$x$data)) {
      if (identical(g$x$data[[i]]$name, "Indicateur")) g$x$data[[i]]$yaxis <- "y2"
    }
    
    g |>
      plotly::layout(
        hovermode = "x unified",
        legend = list(orientation = "h", x = 0, y = -0.1),
        yaxis  = list(autorange = TRUE, tickmode = "auto"),
        yaxis2 = list(overlaying = "y", side = "right",
                      autorange = TRUE, tickmode = "auto",
                      showgrid = FALSE, zeroline = FALSE,     
                      tickfont = g$x$layout$yaxis$tickfont),  
        margin = list(r = 60)                                 
      )
  })
  # Ratio repère/indicateur (RI)
  output$plot_ratio_ri <- plotly::renderPlotly({
    dat <- calage()
    dat$ratio_RI <- dat$serie_calee / dat$indicateur
    mois <- as.integer(format(dat$trimestre, "%m"))
    dat$etiquette <- paste0("T", (mois - 1) %/% 3 + 1, " ", format(dat$trimestre, "%Y"))
    
    p <- ggplot(dat, aes(x = trimestre, y = ratio_RI, group = 1,
                         text = paste0(etiquette, " : ", round(ratio_RI, 3)))) +
      geom_line(color = PALETTE_CATEGORIELLE[1], linewidth = 1) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                   expand = expansion(mult = c(0.02, 0.02))) +
      labs(title = "Ratio Production/Indicateur", x = NULL, y = "Ratio") +
      theme_general() +
      theme(legend.position = "none",
            plot.background  = element_rect(fill = "white", colour = NA),
            panel.background = element_rect(fill = "white", colour = NA))
    
    plotly::ggplotly(p, tooltip = "text") |>
      plotly::layout(hovermode = "x unified")
  })
  
  
  # ============================================================
  # ONGLET : Tableau de bord
  # ============================================================
  
  # Remplit le sélecteur d'année avec les années présentes dans les données
  observe({
    annees <- sort(unique(as.integer(format(donnees()$trimestriel$trimestre, "%Y"))), decreasing = TRUE)
    updateSelectInput(session, "annee_tdb", choices = annees, selected = annees[1])
  })
  
  # Cartes des totaux annuels (production, VA, revenu mixte)
  output$cartes_kpi <- renderUI({
    req(input$annee_tdb)
    a <- agregats()
    a <- a[a$annee == input$annee_tdb, ]
    tot <- colSums(a[, c("prod", "va", "rm")])
    fmt <- function(x) format(round(x, 1), nsmall = 1, big.mark = " ", decimal.mark = ",")
    detail <- paste0("Année ", input$annee_tdb, " (", nrow(a), " trimestre(s))")
    
    fluidRow(
      column(3, carte_kpi("Production",         fmt(tot["prod"]), detail, "#0f8b8d")),
      column(3, carte_kpi("Valeur ajoutée",     fmt(tot["va"]),   detail, "#8e3b6b")),
      column(3, carte_kpi("Revenu mixte",       fmt(tot["rm"]),   detail, "#d98e1f"))
    )
  })
  
  # Graphique d'évolution des quatre agrégats (légende cliquable, pas annuel/trimestriel)
  output$graph_evolution <- plotly::renderPlotly({
    a <- agregats()
    a$date      <- as.Date(paste0(a$annee, "-", (a$trimestre - 1) * 3 + 1, "-01"))
    a$etiquette <- paste0("T", a$trimestre, " ", a$annee)
    
    # Pas annuel : on somme les 4 trimestres, uniquement pour les années complètes
    if (input$pas_tdb == "ann") {
      n_trim <- table(a$annee)
      a <- a[a$annee %in% as.integer(names(n_trim)[n_trim == 4]), ]
      a <- aggregate(cbind(prod, va, rm) ~ annee, data = a, FUN = sum)
      a$date      <- as.Date(paste0(a$annee, "-01-01"))
      a$etiquette <- as.character(a$annee)
    }
    
    # Format « long » : une ligne par (période, agrégat)
    noms <- c("Production", "Valeur ajoutée", "Revenu mixte")
    long <- data.frame(
      date      = rep(a$date, 3),
      etiquette = rep(a$etiquette, 3),
      agregat   = factor(rep(noms, each = nrow(a)), levels = noms),
      valeur    = c(a$prod, a$va, a$rm)
    )
    
    p <- ggplot(long, aes(x = date, y = valeur, color = agregat, group = agregat,
                          text = paste0(etiquette, " – ", agregat, " : ", round(valeur, 1)))) +
      geom_line(linewidth = 1) +
      scale_color_manual(values = c("Production"         = "#0f8b8d",
                                    "Valeur ajoutée"     = "#8e3b6b",
                                    "Revenu mixte"       = "#d98e1f")) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
      labs(x = NULL, y = NULL, color = NULL) +
      theme_general()
    
    plotly::ggplotly(p, tooltip = "text") |>
      plotly::layout(hovermode = "x unified")
  })
}

shinyApp(ui, server)