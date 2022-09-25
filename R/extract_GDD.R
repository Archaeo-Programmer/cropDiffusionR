#' @name extract_GDD
#' @title Extract annual accumulated growing degree days
#'
#' @description `extract_GDD()` extracts annual accumulated growing degree days from WorldClim 2.0 for 1970 to 2000 at site locations.
#'
#' @param sites A data.frame with an ID and sfc_Point geometry containing site locations.
#' @return A tibble with growing degree days for each ID.
#' @importFrom magrittr `%<>%` `%>%`
#' @export
extract_GDD <-
  function(sites) {

    # Get annual accumulated growing degree days.
    terra::extract(x = cropDiffusionR::NASW_gdd,
                    y = sites) %>%
      dplyr::bind_cols(LabID = sites$LabID, GDD = .)
    
  }
