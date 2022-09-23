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
    terra::extract(x = cropDiffusionR::NASW_gdd,
                    y = sites) %>%
      dplyr::bind_cols(LabID = sites$LabID, GDD = .)
    
  }
