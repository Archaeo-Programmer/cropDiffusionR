#' @name extract_GDD
#' @title Extract GDD from WorldClim 2.0
#'
#' @description Extract GDD from WorldClim 2.0 for 1970 to 2000 at Site Locations
#'
#' @param sites A data.frame with an ID and sfc_Point geometry.
#' @return A tibble with growing degree days for each ID.
#' @importFrom magrittr `%<>%` `%>%`
#' @importFrom stats na.omit
#' @export
extract_GDD <-
  function(sites) {
    # Processing WorldClim data.
    # Calculate average days per month during 1970-2000.
    month_days <-
      tibble::tibble(date = seq(
        lubridate::as_date("1970-01-01"),
        lubridate::as_date("2000-12-31"),
        "1 day"
      )) %>%
      dplyr::mutate(year = lubridate::year(date),
                    month = strftime(date, '%B')) %>%
      dplyr::group_by(year, month) %>%
      dplyr::count() %>%
      dplyr::group_by(month) %>%
      dplyr::summarise(`days` = mean(n))
    
    current.list <-
      list.files(path = "/Users/andrewgillreath-brown/Downloads/wc2.1_30s_tavg",
                 pattern = ".tif",
                 full.names = TRUE)
    c.stack <- raster::stack(current.list)
    
    # Get annual accumulated growing degree days.
    raster::extract(x = c.stack,
                    y = sites) %>%
      `colnames<-`(month.name) %>%
      dplyr::bind_cols(Lab_code = sites$Lab_code, .) %>%
      tidyr::pivot_longer(-Lab_code) %>%
      dplyr::left_join(., month_days, by = c("name" = "month")) %>%
      dplyr::mutate(value = dplyr::case_when(value < 10.00 ~ 10.00,
                                             value > 30.00 ~ 30.00,
                                             TRUE ~ value)) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(month_GDD = (value - 10.00) * days) %>%
      dplyr::group_by(Lab_code) %>%
      dplyr::summarise(gdd = sum(month_GDD)) %>%
      dplyr::left_join(., sites, by = "Lab_code") %>%
      dplyr::filter(!is.na(gdd))
    
  }
