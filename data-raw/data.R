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
incomplete_SiteID <- toupper(c("42BEà", "42SA", "5LPà", "LAà", "42à", "42EMà", "42MDà", "42UNà", "42WNà", "5STà", "BB:6:à", "X:12:2à", "BB:", "AA:", "EE:", paste0(LETTERS, ":")))

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
  dplyr::select(names(
    readr::read_csv(
      here::here("data-raw/Maize_Database_NO_Locations.csv"),
      show_col_types = FALSE
    )
  )) %>%
  # Remove any duplicate rows.
  dplyr::distinct() %>%
  #Currently, some known errors in p3k14c data, so adjusting specific rows here.
  # First, remove the rows with errors.
  dplyr::filter(!LabID %in% correct_data) %>%
  # Then, add the rows back to our database.
  dplyr::bind_rows(maizeDB_orig %>% dplyr::filter(LabID %in% correct_data)) %>%
  dplyr::arrange(LabID) %>%
  dplyr::mutate(
    # Convert SiteIDs to uppercase for consistency.
    SiteID = trimws(toupper(SiteID)),
    # Some siteIDs are incomplete/incorrect, so replace with NA.
    SiteID = ifelse(SiteID %in% incomplete_SiteID, NA_character_, SiteID),
    # Remove the parentheses from many of the Arizona sample site IDs.
    SiteID = trimws(stringr::str_replace(SiteID, " \\s*\\([^\\)]+\\)", "")),
    # Also, remove the starting AZ on some of the Arizona sample site IDs.
    SiteID = stringr::str_replace(SiteID, "^(AZ )", "")
  ) %>%
  # Remove the leading 0s on some siteIDs so that these are consistent.
  # First, we separate the beginning part of the SiteID from the ending number.
  tidyr::separate(
    SiteID,
    into = c("SiteID1", "SiteID2"),
    "(?<=[[:alpha:]][[:alpha:]])",
    remove = FALSE
  ) %>%
  # Then, convert to numeric to remove any leading 0s. This does not apply to Arizona or Mexico sites, since the numbering systems are different.
  dplyr::mutate(
    SiteID2 = as.numeric(SiteID2),
    SiteID = ifelse(
      Province != "Arizona" &
        Country != "Mexico" &
        SiteID2 > 0 &
        !SiteName %in% c("CKL-1-190810-8-1", "PY0810-1-1", "LA 18091"),
      paste0(SiteID1, SiteID2),
      SiteID
    )
  ) %>%
  dplyr::select(-c(SiteID1, SiteID2)) %>%
  # Fill in any missing site IDs by SiteName.
  dplyr::group_by(SiteName) %>%
  tidyr::fill(SiteID, .direction = "updown") %>%
  # Fill in any missing site names by SiteID.
  dplyr::group_by(SiteID) %>%
  tidyr::fill(SiteName, .direction = "updown") %>%
  dplyr::mutate(SiteIDName = dplyr::coalesce(SiteID, SiteName)) %>%
  dplyr::ungroup() %>%
  suppressWarnings()

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


# Accumulated growing degree days (GDD) °C for the year with a base temperature of 10°C and a max of 30°C using WorldClim.

# Calculate average days per month during 1970-2000.
month_days <-
  tibble::tibble(date = seq(
    lubridate::as_date("1970-01-01"),
    lubridate::as_date("2000-12-31"),
    "1 day"
  )) %>%
  dplyr::mutate(year = lubridate::year(date),
                month = lubridate::month(date)) %>%
  dplyr::group_by(year, month) %>%
  dplyr::count() %>%
  dplyr::group_by(month) %>%
  dplyr::summarise(`days` = mean(n)) %>% 
  dplyr::pull(days)

# Data was downloaded from https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tmin.zip and 
# https://biogeo.ucdavis.edu/data/worldclim/v2.1/base/wc2.1_30s_tmax.zip,
# then was converted to a rasterstack. Here, we run the data locally, as the files are too big to
# do a temporary file.

# Get tmin data.
current.list.min <-
  list.files(path = "./../../../../../Downloads/wc2.1_30s_tmin",
             pattern = ".tif",
             full.names = TRUE)
c.stack.min <- raster::stack(current.list.min)

# Crop to extent of southwestern US and Mexico.
my_stack_min <- raster::stack(raster::crop(c.stack.min, cropDiffusionR::usa_mexico_states))
# Mask out (i.e. assign NA) the values outside the polygon.
my_stack_min2 <- raster::brick(raster::mask(my_stack_min, cropDiffusionR::usa_mexico_states))

# Get tmax data.
current.list.max <-
  list.files(path = "./../../../../../Downloads/wc2.1_30s_tmax",
             pattern = ".tif",
             full.names = TRUE)
c.stack.max <- raster::stack(current.list.max)

# Crop to extent of southwestern US and Mexico.
my_stack_max <- raster::stack(raster::crop(c.stack.max, cropDiffusionR::usa_mexico_states))
# Mask out (i.e. assign NA) the values outside the polygon.
my_stack_max2 <- raster::brick(raster::mask(my_stack_max, cropDiffusionR::usa_mexico_states))

# Get GDD for each month.
WorldClim_monthly_gdd <- list(my_stack_min2, my_stack_max2) %>%
  purrr::reduce(
    .f = function(x, y) {
      paleomat::calc_gdd(
        tmin = x,
        tmax = y,
        t.base = 10,
        t.cap = 30
      )
    }
  ) %>%
  # Multiply by the number of days in a month to get the total accumulated GDD for each month.
  {
    . * month_days
  }

# Sum all 12 months.
WorldClim_annual_gdd <- sum(WorldClim_monthly_gdd, na.rm = FALSE)

usethis::use_data(WorldClim_annual_gdd,
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
swus_states <-
  sf::st_as_sf(maps::map("state", fill = TRUE, plot = FALSE)) %>%
  sf::st_transform(., crs = 4326) %>%
  dplyr::filter(ID %in% c("colorado", "utah", "arizona", "new mexico")) %>%
  dplyr::rename(state_name = ID) %>%
  dplyr::mutate(
    state_name = stringr::str_to_title(state_name),
    state_abbr = dplyr::case_when(
      state_name == "Arizona" ~ "AZ",
      state_name == "Colorado" ~ "CO",
      state_name == "Utah" ~ "UT",
      state_name == "New Mexico" ~ "NM",
      TRUE ~ NA_character_
    )
  ) %>%
  dplyr::mutate(country = "USA")

# Save data for the Four Corners states.
usethis::use_data(swus_states,
                  overwrite = TRUE)

# Bind together to make a SWUS and Mexico file.
swus_mexico_states <- dplyr::bind_rows(swus_states, mexico_states)

usethis::use_data(swus_mexico_states,
                  overwrite = TRUE)


# Digital elevation model for the four corner states and Mexico (i.e., the North American Southwest).
NASW_elevation <- elevatr::get_elev_raster(locations = cropDiffusionR::usa_mexico_states, z = 10)

usethis::use_data(NASW_elevation,
                  overwrite = TRUE)
