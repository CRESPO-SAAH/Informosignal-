library(httr2)

appeler_LLM <- function(messages, outils) {
  resp <- request("https://api.groq.com/openai/v1/chat/completions") |>
    req_auth_bearer_token(Sys.getenv("GROQ_API_KEY")) |>
    req_body_json(list(
      model = "openai/gpt-oss-20b",
      messages = messages,
      tools = outils
    )) |>
    req_perform()
  
  resp_body_json(resp)$choices[[1]]$message
}
                              