usa <-
  sf::st_as_sf(maps::map("state", fill = TRUE, plot = FALSE)) %>%
  sf::st_transform(., crs = 4326) %>%
  dplyr::filter(ID %in% c("colorado", "utah", "arizona", "new mexico")) %>%
  dplyr::rename(state_name = ID, geometry = geom) %>%
  dplyr::mutate(
    state_name = stringr::str_to_title(state_name),
    state_abbr = case_when(
      state_name == "Arizona" ~ "AZ",
      state_name == "Colorado" ~ "CO",
      state_name == "Utah" ~ "UT",
      state_name == "New Mexico" ~ "NM",
      TRUE ~ NA_character_
    )
  )

mexico <-
  sf::st_as_sf(maps::map(
    "world",
    regions = "mexico",
    fill = TRUE,
    plot = FALSE
  )) %>%
  sf::st_transform(., crs = 4326)

mexico_states <-
  # Downloaded from https://www.arcgis.com/home/item.html?id=ac9041c51b5c49c683fbfec61dc03ba8
  sf::read_sf("/Users/andrew/Downloads/mexstates/mexstates.shp") %>%
  dplyr::left_join(
    .,
    mxmaps::df_mxstate_2020 %>% dplyr::select(state_name, state_abbr) %>% dplyr::mutate(
      state_name = stringi::stri_trans_general(state_name, id = "Latin-ASCII")
    ),
    by = c("ADMIN_NAME" = "state_name")
  ) %>%
  dplyr::select(state_name = ADMIN_NAME, state_abbr)

# mexico_states <- mxmaps::mxstate.map %>%
#   dplyr::left_join(., mxmaps::df_mxstate_2020 %>% dplyr::select(region, state_name, state_abbr), by = "region") %>% 
#   sf::st_as_sf(coords = c("long", "lat"), crs = 4326) %>%
#   sf::st_transform(., crs = 4326) %>% 
#   dplyr::group_by(region, state_name, state_abbr) %>% 
#   #sf::st_combine() %>% 
#   dplyr::summarize() %>% 
#   sf::st_cast("POLYGON") %>% 
#   sf::st_cast("MULTIPOLYGON")

usa_mexico_states <- dplyr::bind_rows(usa, mexico_states)

both <- bind_rows(usa, mexico)

sfg_list <- sf::st_sfc(both$geom)

out <- sf::st_combine(sfg_list)

outsp <- as(out, 'Spatial')


current.list <-
  list.files(path = "/Users/andrew/Downloads/wc2.1_30s_tavg",
             pattern = ".tif",
             full.names = TRUE)
c.stack <- raster::stack(current.list)


my_stack <- stack(raster::crop(c.stack, outsp))
#then mask out (i.e. assign NA) the values outside the polygon
my_stack2 <- stack(raster::mask(my_stack, outsp))


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
  dplyr::summarise(`days` = mean(n))


# Get annual accumulated growing degree days.
my_stack2[my_stack2 < 10] <- 10.0
#calc(my_stack2, function(y) ifelse(y < 10, 10, y))
my_stack2[my_stack2 > 30] <- 30.0
#calc(my_stack2, function(y) ifelse(y > 30, 30, y))

my_stack2$layer.1 <- ((my_stack2$layer.1 - 10.00) * 31)
my_stack2$layer.2 <- ((my_stack2$layer.2 - 10.00) * 28.3)
my_stack2$layer.3 <- ((my_stack2$layer.3 - 10.00) * 31)
my_stack2$layer.4 <- ((my_stack2$layer.4 - 10.00) * 30)
my_stack2$layer.5 <- ((my_stack2$layer.5 - 10.00) * 31)
my_stack2$layer.6 <- ((my_stack2$layer.6 - 10.00) * 30)
my_stack2$layer.7 <- ((my_stack2$layer.7 - 10.00) * 31)
my_stack2$layer.8 <- ((my_stack2$layer.8 - 10.00) * 31)
my_stack2$layer.9 <- ((my_stack2$layer.9 - 10.00) * 30)
my_stack2$layer.10 <- ((my_stack2$layer.10 - 10.00) * 31)
my_stack2$layer.11 <- ((my_stack2$layer.11 - 10.00) * 30)
my_stack2$layer.12 <- ((my_stack2$layer.12 - 10.00) * 31)

accum_GDD_annual <- sum(my_stack2)

# rev(RColorBrewer::brewer.pal(11, "RdYlBu"))
# RColorBrewer::brewer.pal(10, "Spectral")
# RColorBrewer::brewer.pal(6,"Dark2")

#colorRampPalette(rev(RColorBrewer::brewer.pal(11, "RdBu")))(255)
  
  
  
  
  