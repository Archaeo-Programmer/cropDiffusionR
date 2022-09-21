library(magrittr)

# Accumulated growing degree days for the year with a base temperature of 5 degrees Celsius.
# Data was downloaded from https://sage.nelson.wisc.edu/data-and-models/atlas-of-the-biosphere/mapping-the-biosphere/ecosystems/growing-degree-days/,
# then was converted to a raster from a ArcGIS format. 
global_gdd <- raster::raster(here::here("data-raw/gdd1.tif"), crs = "+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs")

usethis::use_data(global_gdd,
                  overwrite = TRUE)


# Ancient Maize database from various sources. Here, we will join the data to the data from the p3k14c R package, which will take precedence over data listed, as it was checked more systematically.
maizeDB <-
  readr::read_csv(here::here("data-raw/Maize_Database_NO_Locations.csv"),
                  col_types = readr::cols()) %>%
  dplyr::left_join(
    .,
    p3k14c::p3k14c_data %>% dplyr::select(LabID, Age, Error, d13C, SiteID, SiteName, Method),
    by = "LabID"
  ) %>%
  dplyr::mutate(
    Age = dplyr::coalesce(Age.y, Age.x),
    Error = dplyr::coalesce(Error.y, Error.x),
    d13C = dplyr::coalesce(as.numeric(d13C.y), d13C.x),
    Method = dplyr::coalesce(Method.y, Method.x),
    SiteID = dplyr::coalesce(SiteID.x, SiteID.y),
    SiteName = dplyr::coalesce(SiteName.x, SiteName.y)
  ) %>% 
  dplyr::select(-contains(c(".x", ".y"))) %>% 
  dplyr::select(names(readr::read_csv(here::here("data-raw/Maize_Database_NO_Locations.csv"), show_col_types = FALSE))) %>% 
  # Remove any duplicate rows.
  dplyr::distinct()

# Here, we calibrate the data using the same calibration curve (i.e., IntCAL20).
rcarbon_output <-
  rcarbon::calibrate(
    # normalized age
    x = maizeDB$Age,
    # one sigma error
    errors = maizeDB$Error,
    ids = maizeDB$LabID,
    # unique ID for each
    calCurves = "intcal20"
  ) %>%
  summary() %>% 
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ stringr::str_replace_all(.x, "NA to NA", NA_character_)))

# Merge the calibration data to the maize database.
maizeDB <- dplyr::left_join(maizeDB, rcarbon_output, by = c("LabID" = "DateID")) %>% 
  dplyr::relocate(MedianBP, .after = Province) %>% 
  dplyr::relocate(Source, .after = last_col()) %>% 
  dplyr::mutate(MedianBP = as.numeric(MedianBP))

usethis::use_data(maizeDB,
                  overwrite = TRUE)


# Accumulated growing degree days for the year with a base temperature of 10 degrees Celsius.
# Data was downloaded from https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tavg.zip,
# then was converted to a rasterstack. 
NASW_gdd <- accum_GDD_annual

usethis::use_data(NASW_gdd,
                  overwrite = TRUE)
