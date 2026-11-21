if (!require('pacman')) install.packages('pacman'); library('pacman')
pacman::p_load(
  tidyverse,
  dplyr,
  randomNames
)
env <- new.env()
load("data/immunABC.EIR.rda", envir = env)
eir <- env$immunABC.EIR

# One row per person: keep the residence of their earliest vaccination
immunABC.pop_ids <- eir %>%
    arrange(ID, date_vax) %>%
    distinct(ID, .keep_all = TRUE) %>%
    select(
      ID,
      date_birth,
      ADM1_residence,
      ADM2_residence
    )

set.seed(42)
n <- nrow(immunABC.pop_ids)
first    <- randomNames(n, which.names = "first", ethnicity = 4)
paternal <- randomNames(n, which.names = "last",  ethnicity = 4)
maternal <- randomNames(n, which.names = "last",  ethnicity = 4)
immunABC.pop_ids$name <- paste(first, paternal, maternal)

save(immunABC.pop_ids, file = "data/immunABC.pop_ids.rda")
#immunABC.pop_ids$name <- randomNames::randomNames(nrow(immunABC.pop_ids), ethnicity = 4)
