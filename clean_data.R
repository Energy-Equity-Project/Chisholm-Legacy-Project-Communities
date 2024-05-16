
# Libraries
library(tidyverse)
library(janitor)

# Directories
datadir <- "data"
acs_datadir <- file.path(datadir, "acs_data")
clean_datadir <- file.path(datadir, "clean_data")
clean_acs_dir <- file.path(clean_datadir, "acs_data")

# Create output directories if necessary
if (!file.exists(clean_datadir)) { dir.create(clean_datadir) }
if (!file.exists(clean_acs_dir)) { dir.create(clean_acs_dir) }


# Clean population data B01003
pop_files <- list.files(acs_datadir, pattern = "B02001", full.names = TRUE)
pop <- data.frame()
for (i in 1:length(pop_files)) {
  print(paste("Processing", pop_files[i]))
  curr_pop <- read.csv(pop_files[i]) %>%
    clean_names() %>%
    # Keep only columns needed
    select(matches("b02001_00[1,3]e$|geo_id|name$|state|county|tract|tclp_region")) %>%
    distinct() %>%
    rename(total_pop = b02001_001e,
           black_pop = b02001_003e) %>%
    # separate name to state, county and census tract names
    separate_wider_delim(cols = c(name), delim = "; ", names = c("census_tract_name", "county_name", "state_name")) %>%
    mutate(percent_black = 100 * (black_pop / total_pop))
  
  pop <- pop %>%
    bind_rows(curr_pop)
}
print("Writing processed population data")
write.csv(pop, file.path(clean_acs_dir, "population.csv"), row.names = FALSE)

# ACS variables denoting income level less than $40,000
total_less_than_40k_vars <- c("b19001_002e", "b19001_003e", "b19001_004e",
                              "b19001_005e", "b19001_006e", "b19001_007e",
                              "b19001_008e")
black_less_than_40k_vars <- c("b19001b_002e", "b19001b_003e", "b19001b_004e",
                              "b19001b_005e", "b19001b_006e", "b19001b_007e",
                              "b19001b_008e")

# Read in all files relating to total number of households
total_hh_files <- list.files(acs_datadir, pattern = "[0-9][0-9]_B19001\\.csv", full.names = TRUE)
total_hh <- data.frame()

for (i in 1:length(total_hh_files)) {
  print(paste("Processing", total_hh_files[i]))
  curr_total_hh <- read.csv(total_hh_files[i])
  curr_total_hh <- curr_total_hh %>%
    clean_names() %>%
    # Keep only columns needed
    select(matches("b19001_[0-9][0-9][0-9]e$|geo_id|name$|state|county|tract|tclp_region")) %>%
    distinct() %>%
    # Restructure income level columns
    rename("total_hh"="b19001_001e") %>%
    pivot_longer(-c(geo_id, name, state, county, tract, tclp_region, total_hh), names_to = "acs_var", values_to = "num_hh") %>%
    mutate(income_level = case_when(
      acs_var == "b19001_002e" ~ "less than 10,000",
      acs_var == "b19001_003e" ~ "10,000 - 15,000",
      acs_var == "b19001_004e" ~ "15,000 - 20,000",
      acs_var == "b19001_005e" ~ "20,000 - 25,000",
      acs_var == "b19001_006e" ~ "25,000 - 30,000",
      acs_var == "b19001_007e" ~ "30,000 - 35,000",
      acs_var == "b19001_008e" ~ "35,000 - 40,000",
      acs_var == "b19001_009e" ~ "40,000 - 45,000",
      acs_var == "b19001_010e" ~ "45,000 - 50,000",
      acs_var == "b19001_011e" ~ "50,000 - 60,000",
      acs_var == "b19001_012e" ~ "60,000 - 75,000",
      acs_var == "b19001_013e" ~ "75,000 - 100,000",
      acs_var == "b19001_014e" ~ "100,000 - 125,000",
      acs_var == "b19001_015e" ~ "125,000 - 150,000",
      acs_var == "b19001_016e" ~ "150,000 - 200,000",
      acs_var == "b19001_017e" ~ "200,000+",
      TRUE ~ "error"
    )) %>%
    # calculate number of HH with income >= $40,000
    mutate(less_than_40k = case_when(
      acs_var %in% total_less_than_40k_vars ~ TRUE,
      TRUE ~ FALSE
    )) %>%
    # separate name to state, county and census tract names
    separate_wider_delim(cols = c(name), delim = "; ", names = c("census_tract_name", "county_name", "state_name"))
  
  total_hh <- total_hh %>%
    bind_rows(curr_total_hh)
}

write.csv(total_hh, file.path(clean_acs_dir, "total_hh.csv"), row.names = FALSE)
print("Done processing total number of HH by income level")

# Processing number of Black or African American HH by income level
# Read in all files relating to total number of households
black_hh_files <- list.files(acs_datadir, pattern = "[0-9][0-9]_B19001B\\.csv", full.names = TRUE)
black_hh <- data.frame()

for (i in 1:length(black_hh_files)) {
  print(paste("Processing", black_hh_files[i]))
  curr_black_hh <- read.csv(black_hh_files[i])
  curr_black_hh <- curr_black_hh %>%
    clean_names() %>%
    # Keep only columns needed
    select(matches("b19001b_[0-9][0-9][0-9]e$|geo_id|name$|state|county|tract|tclp_region")) %>%
    distinct() %>%
    # Restructure income level columns
    rename("total_hh"="b19001b_001e") %>%
    pivot_longer(-c(geo_id, name, state, county, tract, tclp_region, total_hh), names_to = "acs_var", values_to = "num_hh") %>%
    mutate(income_level = case_when(
      acs_var == "b19001b_002e" ~ "less than 10,000",
      acs_var == "b19001b_003e" ~ "10,000 - 15,000",
      acs_var == "b19001b_004e" ~ "15,000 - 20,000",
      acs_var == "b19001b_005e" ~ "20,000 - 25,000",
      acs_var == "b19001b_006e" ~ "25,000 - 30,000",
      acs_var == "b19001b_007e" ~ "30,000 - 35,000",
      acs_var == "b19001b_008e" ~ "35,000 - 40,000",
      acs_var == "b19001b_009e" ~ "40,000 - 45,000",
      acs_var == "b19001b_010e" ~ "45,000 - 50,000",
      acs_var == "b19001b_011e" ~ "50,000 - 60,000",
      acs_var == "b19001b_012e" ~ "60,000 - 75,000",
      acs_var == "b19001b_013e" ~ "75,000 - 100,000",
      acs_var == "b19001b_014e" ~ "100,000 - 125,000",
      acs_var == "b19001b_015e" ~ "125,000 - 150,000",
      acs_var == "b19001b_016e" ~ "150,000 - 200,000",
      acs_var == "b19001b_017e" ~ "200,000+",
      TRUE ~ "error"
    )) %>%
    # calculate number of HH with income >= $40,000
    mutate(less_than_40k = case_when(
      acs_var %in% black_less_than_40k_vars ~ TRUE,
      TRUE ~ FALSE
    )) %>%
    # separate name to state, county and census tract names
    separate_wider_delim(cols = c(name), delim = "; ", names = c("census_tract_name", "county_name", "state_name"))
  
  
  black_hh <- black_hh %>%
    bind_rows(curr_black_hh)
}

write.csv(black_hh, file.path(clean_acs_dir, "black_hh.csv"), row.names = FALSE)
print("Done processing total number of HH by income level")


