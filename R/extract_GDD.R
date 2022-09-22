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

    # Get annual accumulated growing degree days.
    raster::extract(x = cropDiffusionR::NASW_gdd,
                    y = sites) %>%
      `colnames<-`(month.name) %>%
      dplyr::bind_cols(LabID = sites$LabID, .) %>%
      tidyr::pivot_longer(-LabID) %>%
      dplyr::left_join(., month_days, by = c("name" = "month")) %>%
      dplyr::mutate(value = dplyr::case_when(value < 10.00 ~ 10.00,
                                             value > 30.00 ~ 30.00,
                                             TRUE ~ value)) %>%
      dplyr::rowwise() %>%
      dplyr::mutate(month_GDD = (value - 10.00) * days) %>%
      dplyr::group_by(LabID) %>%
      dplyr::summarise(gdd = sum(month_GDD)) %>%
      dplyr::left_join(., sites, by = "LabID") %>%
      dplyr::filter(!is.na(gdd))
    
  }
