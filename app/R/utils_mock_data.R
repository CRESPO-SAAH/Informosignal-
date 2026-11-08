generate_mock_data <- function(start = "2017-01-01", end = "2026-04-01", seed = 42) {
  set.seed(seed)
  
  dates <- seq(as.Date(start), as.Date(end), by = "quarter")
  n <- length(dates)
  
  tendance <- cumsum(rnorm(n, mean = 0.5, sd = 1))
  
  mobile_money   <- 100 + tendance * 2   + rnorm(n, 0, 3)
  variable_cible <- 50  + tendance * 1.2 + rnorm(n, 0, 2)
  
  data.frame(trimestre = dates, mobile_money)
}

df <- generate_mock_data()
head(df)
