
# Libraries
library(tidyverse)
library(janitor)
library(sf)

# Directories
datadir <- "data"
acs_datadir <- file.path(datadir, "acs_data")
gis_datadir <- file.path(datadir, "GIS_Layers")
gis_uncompressed_dir <- file.path(gis_datadir, "uncompressed")
clean_datadir <- file.path(datadir, "clean_data")
clean_acs_dir <- file.path(clean_datadir, "acs_data")
outdir <- "outputs"

if (!file.exists(outdir)) { dir.create(outdir) }

pop <- read.csv(file.path(clean_acs_dir, "population.csv"))
black_hh <- read.csv(file.path(clean_acs_dir, "black_hh.csv"))

# Census tracts with at least 30% Black population
black_pop_percent_threshold <- 30
black_pop_tracts <- pop %>%
  filter(percent_black >= black_pop_percent_threshold)

# Census tracts where Black households' median income is less than $40,000
black_hh_40k <- black_hh %>%
  group_by(geo_id, less_than_40k) %>%
  summarize(num_hh = sum(num_hh, na.rm = TRUE)) %>%
  ungroup() %>%
  group_by(geo_id) %>%
  mutate(total_hh = sum(num_hh, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(percent_hh = 100 * (num_hh / total_hh)) %>%
  filter(less_than_40k == TRUE &
           percent_hh >= 50)

# Census tracts with at least 30% Black population AND
# Black population's median income is less than $40,000
tclp_tracts <- black_pop_tracts %>%
  select(geo_id, total_pop, black_pop, percent_black_pop = percent_black) %>%
  left_join(
    black_hh_40k %>%
      select(geo_id, black_hh = total_hh, num_black_hh_less_40k = num_hh, percent_black_hh_40k = percent_hh) %>%
      distinct(),
    by = c("geo_id")
  ) %>%
  filter(!is.na(percent_black_hh_40k))

write.csv(tclp_tracts, file.path(outdir, "tclp_tracts.csv"), row.names = FALSE)


# Read in all GIS layers
shp_files <- list.files(gis_uncompressed_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
tclp_map <- data.frame()

for (i in 1:length(shp_files)) {
  print(paste("Reading shapefile", shp_files[i]))
  curr_shp <- read_sf(shp_files[i]) %>%
    select(GEOID, geometry) %>%
    distinct()
  tclp_map <- tclp_map %>%
    rbind(curr_shp)
}

# Create map of only including census tracts that meeting "Communities of Interest" criteria
tclp_tracts <- tclp_tracts %>%
  separate_wider_delim(cols = geo_id, delim = "US", names = c("tmp", "GEOID")) %>%
  select(-tmp)

tclp_tracts_map <- tclp_tracts %>%
  left_join(
    tclp_map,
    by = c("GEOID")
  )


st_write(tclp_tracts_map, dsn = file.path(outdir, "tclp_tracts_map.geojson"), layer = "tclp")

