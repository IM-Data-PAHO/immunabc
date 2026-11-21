if (!require('pacman')) install.packages('pacman'); library('pacman')
pacman::p_load(
  tidyverse,
  dplyr,
  lubridate,
  randomNames
)
env <- new.env()
load("data/immunABC.pop_ids.rda", envir = env)
load("data/immunABC.pop.ADM2.rda", envir = env)
pop_ids  <- env$immunABC.pop_ids
pop_adm2 <- env$immunABC.pop.ADM2

strip_hyphen <- function(x) sub("-.*$", "", x)

# Existing names are "given paternal maternal": only the surnames lose their hyphenated part
pop_ids <- pop_ids %>%
  mutate(
    given    = sub(" .*$", "", name),
    surnames = gsub("-\\S*", "", sub("^\\S+ ?", "", name)),
    name     = trimws(paste(given, surnames))
  ) %>%
  select(-given, -surnames)

# Population aged 0 in a given year is the birth cohort of that year
target <- pop_adm2 %>%
  filter(age == 0) %>%
  select(
    ADM1_residence = ADM1,
    ADM2_residence = ADM2,
    birth_year = year,
    population
  )

current <- pop_ids %>%
  mutate(birth_year = year(date_birth)) %>%
  count(ADM1_residence, ADM2_residence, birth_year, name = "current")

gap <- target %>%
  left_join(current, by = c("ADM1_residence", "ADM2_residence", "birth_year")) %>%
  mutate(
    current = coalesce(current, 0L),
    to_add  = as.integer(pmax(round(population) - current, 0))
  )

over <- gap %>% filter(current > population)
if (nrow(over) > 0) {
  message(nrow(over), " district-year groups already exceed their population and get no new rows")
}

draw_birth_dates <- function(n, pool, birth_year) {
  first_day <- make_date(birth_year, 1, 1)
  last_day  <- make_date(birth_year, 12, 31)
  if (length(pool) == 0) {
    return(first_day + sample(0:as.integer(last_day - first_day), n, replace = TRUE))
  }
  dates <- pool[sample.int(length(pool), n, replace = TRUE)] + sample(-3:3, n, replace = TRUE)
  pmin(pmax(dates, first_day), last_day)
}

donors <- pop_ids %>%
  mutate(birth_year = year(date_birth)) %>%
  select(ADM1_residence, ADM2_residence, birth_year, date_birth)

set.seed(42)

new_rows <- gap %>%
  filter(to_add > 0) %>%
  select(ADM1_residence, ADM2_residence, birth_year, to_add) %>%
  uncount(to_add) %>%
  group_by(ADM1_residence, ADM2_residence, birth_year) %>%
  group_modify(function(df, key) {
    pool <- donors %>%
      semi_join(key, by = names(key)) %>%
      pull(date_birth)
    df$date_birth <- draw_birth_dates(nrow(df), as.Date(pool), key$birth_year)
    df
  }) %>%
  ungroup()

n_new <- nrow(new_rows)
if (n_new > 0) {
  first    <- randomNames(n_new, which.names = "first", ethnicity = 4)
  paternal <- strip_hyphen(randomNames(n_new, which.names = "last", ethnicity = 4))
  maternal <- strip_hyphen(randomNames(n_new, which.names = "last", ethnicity = 4))
  new_rows$name <- paste(first, paternal, maternal)
  new_rows$ID   <- max(pop_ids$ID) + seq_len(n_new)
}

immunABC.pop_ids_expanded_to_pop <- bind_rows(
  pop_ids,
  new_rows %>% select(all_of(names(pop_ids)))
)

check <- immunABC.pop_ids_expanded_to_pop %>%
  mutate(birth_year = year(date_birth)) %>%
  count(ADM1_residence, ADM2_residence, birth_year, name = "people") %>%
  inner_join(target, by = c("ADM1_residence", "ADM2_residence", "birth_year")) %>%
  mutate(difference = people - round(population))

message(nrow(pop_ids), " original people + ", n_new, " new = ", nrow(immunABC.pop_ids_expanded_to_pop))
message("District-year groups off target: ", sum(check$difference != 0))
print(head(immunABC.pop_ids_expanded_to_pop))

save(immunABC.pop_ids_expanded_to_pop, file = "data/immunABC.pop_ids_expanded_to_pop.rda")
