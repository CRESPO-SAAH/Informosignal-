library(shiny)

# Fabrique une carte KPI.

carte_kpi <- function(titre, valeur, detail = NULL, couleur = "#8b5e34") {
  div(
    class = "carte-kpi",
    style = paste0("border-top: 4px solid ", couleur, ";"),
    div(class = "carte-titre", titre),
    div(class = "carte-valeur", valeur),
    if (!is.null(detail)) div(class = "carte-detail", detail)
  )
}


style_cartes <- function() {
  tags$head(tags$style(HTML("
    .carte-kpi    { background: #ffffff; border: 1px solid #e3d9c8;
                    border-radius: 10px; padding: 14px 16px; margin-bottom: 14px; }
    .carte-titre  { font-size: 13px; color: #7a6a55; }
    .carte-valeur { font-size: 30px; font-weight: 700; line-height: 1.15;
                    margin: 4px 0; }
    .carte-detail { font-size: 13px; color: #7a6a55; }
  ")))
}