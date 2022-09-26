library(magrittr)
devtools::install_github('diegovalle/mxmaps')

# Accumulated growing degree days for the year with a base temperature of 5 degrees Celsius.
# Data was downloaded from https://sage.nelson.wisc.edu/data-and-models/atlas-of-the-biosphere/mapping-the-biosphere/ecosystems/growing-degree-days/,
# then was converted to a raster from a ArcGIS format. 
global_gdd <- raster::raster(here::here("data-raw/gdd1.tif"), crs = "+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs")

usethis::use_data(global_gdd,
                  overwrite = TRUE)


# Ancient Maize database from various sources. Here, we will join the data to the data from the p3k14c R package, which will take precedence over data listed, as it was checked more systematically.
maizeDB_orig <-
  readr::read_csv(here::here("data-raw/Maize_Database_NO_Locations.csv"),
                  col_types = readr::cols()) %>% 
  dplyr::arrange(LabID) %>% 
  dplyr::filter(Province %in% c("Arizona", "New Mexico", "Utah", "Colorado") | Country == "Mexico")

# Currently, some known errors in p3k14c data, so adjusting specific rows here. Here is a vector with LabIDs that need to default to the csv file instead of p3k14c::p3k14c_data.
correct_data <- c("AA-3308", "A-2791", "A-4183", "AA-6403", "Beta-402794", "Beta-76002", "RL-175")

maize_DB <- 
  dplyr::left_join(
    maizeDB_orig,
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
  dplyr::distinct() %>% 
  #Currently, some known errors in p3k14c data, so adjusting specific rows here.
  dplyr::filter(!LabID %in% correct_data) %>% 
  dplyr::bind_rows(maizeDB_orig %>% dplyr::filter(LabID %in% correct_data)) %>% 
  dplyr::arrange(LabID)
  
# We can check which rows have different ages. In a few cases, p3k14c had incorrect data.
# View(maize_DB[maizeDB_orig$Age != maize_DB$Age,])
# View(maizeDB_orig[maizeDB_orig$Age != maize_DB$Age,])

# Here, we calibrate the data using the same calibration curve (i.e., IntCal20).
rcarbon_output <-
  rcarbon::calibrate(
    # normalized age
    x = maize_DB$Age,
    # one sigma error
    errors = maize_DB$Error,
    # unique ID for each
    ids = maize_DB$LabID,
    # specify the calibration curve
    calCurves = "intcal20"
  ) %>%
  summary() %>% 
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ stringr::str_replace_all(.x, "NA to NA", NA_character_)))

# Merge the calibration data to the maize database.
maizeDB <- dplyr::left_join(maize_DB, rcarbon_output, by = c("LabID" = "DateID")) %>% 
  dplyr::relocate(MedianBP, .after = Error) %>% 
  dplyr::relocate(Source, .after = last_col()) %>% 
  dplyr::mutate(MedianBP = as.numeric(MedianBP), 
                Date = rcarbon::BPtoBCAD(MedianBP)) %>% 
  dplyr::relocate(Date, .after = MedianBP)

usethis::use_data(maizeDB,
                  overwrite = TRUE)


# Accumulated growing degree days for the year with a base temperature of 10 degrees Celsius.
# Data was downloaded from https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tavg.zip,
# then was converted to a rasterstack. Here, we run the data locally, as the files are too big to 
# do a temporary file.
# current.list <-
#   list.files(path = "/Users/andrew/Downloads/wc2.1_30s_tavg",
#              pattern = ".tif",
#              full.names = TRUE)
# c.stack <- raster::stack(current.list)
# 
# 
# my_stack <- raster::stack(raster::crop(c.stack, outsp))
# #then mask out (i.e. assign NA) the values outside the polygon
# my_stack2 <- raster::stack(raster::mask(my_stack, outsp))
# 
# 
# # Calculate average days per month during 1970-2000.
# month_days <-
#   tibble::tibble(date = seq(
#     lubridate::as_date("1970-01-01"),
#     lubridate::as_date("2000-12-31"),
#     "1 day"
#   )) %>%
#   dplyr::mutate(year = lubridate::year(date),
#                 month = lubridate::month(date)) %>%
#   dplyr::group_by(year, month) %>%
#   dplyr::count() %>%
#   dplyr::group_by(month) %>%
#   dplyr::summarise(`days` = mean(n))
# 
# 
# # Get annual accumulated growing degree days for each month.
# # Here, we use a base of 10°C and the max of 30°C. 
# my_stack2[my_stack2 < 10] <- 10.0
# my_stack2[my_stack2 > 30] <- 30.0
# 
# # Then, we get the accumulated growing degree days for each month.
# my_stack2$wc2.1_30s_tavg_01 <- ((my_stack2$wc2.1_30s_tavg_01 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_02 <- ((my_stack2$wc2.1_30s_tavg_02 - 10.00) * 28.3)
# my_stack2$wc2.1_30s_tavg_03 <- ((my_stack2$wc2.1_30s_tavg_03 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_04 <- ((my_stack2$wc2.1_30s_tavg_04 - 10.00) * 30)
# my_stack2$wc2.1_30s_tavg_05 <- ((my_stack2$wc2.1_30s_tavg_05 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_06 <- ((my_stack2$wc2.1_30s_tavg_06 - 10.00) * 30)
# my_stack2$wc2.1_30s_tavg_07 <- ((my_stack2$wc2.1_30s_tavg_07 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_08 <- ((my_stack2$wc2.1_30s_tavg_08 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_09 <- ((my_stack2$wc2.1_30s_tavg_09 - 10.00) * 30)
# my_stack2$wc2.1_30s_tavg_10 <- ((my_stack2$wc2.1_30s_tavg_10 - 10.00) * 31)
# my_stack2$wc2.1_30s_tavg_11 <- ((my_stack2$wc2.1_30s_tavg_11 - 10.00) * 30)
# my_stack2$wc2.1_30s_tavg_12 <- ((my_stack2$wc2.1_30s_tavg_12 - 10.00) * 31)
# 
# # Sum all 12 months.
# accum_GDD_annual <- sum(my_stack2)
NASW_gdd <- accum_GDD_annual

usethis::use_data(NASW_gdd,
                  overwrite = TRUE)

# Create southwestern United States and Mexico states polygon.
# Get Mexico states shapefile. Data was downloaded from https://www.arcgis.com/home/item.html?id=ac9041c51b5c49c683fbfec61dc03ba8.
mexico_states <-
  sf::read_sf(here::here("data-raw/mexstates/mexstates.shp")) %>%
  dplyr::left_join(
    .,
    mxmaps::df_mxstate_2020 %>% dplyr::select(state_name, state_abbr) %>% dplyr::mutate(
      state_name = stringi::stri_trans_general(state_name, id = "Latin-ASCII")
    ),
    by = c("ADMIN_NAME" = "state_name")
  ) %>%
  dplyr::select(state_name = ADMIN_NAME, state_abbr, geom = geometry) %>% 
  dplyr::mutate(country = "Mexico")

# Get USA states data from southwestern United States.
usa <-
  sf::st_as_sf(maps::map("state", fill = TRUE, plot = FALSE)) %>%
  sf::st_transform(., crs = 4326) %>%
  dplyr::filter(ID %in% c("colorado", "utah", "arizona", "new mexico")) %>%
  dplyr::rename(state_name = ID) %>%
  dplyr::mutate(
    state_name = stringr::str_to_title(state_name),
    state_abbr = case_when(
      state_name == "Arizona" ~ "AZ",
      state_name == "Colorado" ~ "CO",
      state_name == "Utah" ~ "UT",
      state_name == "New Mexico" ~ "NM",
      TRUE ~ NA_character_
    )
  ) %>% 
  dplyr::mutate(country = "USA")

# Bind together.
usa_mexico_states <- dplyr::bind_rows(usa, mexico_states)

usethis::use_data(usa_mexico_states,
                  overwrite = TRUE)


# Digital elevation model for the four corner states and Mexico (i.e., the North American Southwest). 
NASW_elevation <- elevatr::get_elev_raster(locations = cropDiffusionR::usa_mexico_states, z = 10)

usethis::use_data(NASW_elevation,
                  overwrite = TRUE)
