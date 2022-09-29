#' @name extract_GDD
#' @title Extract growing degree days
#'
#' @description `extract_GDD()` extracts growing degree days from a user provided GDD raster dataset at site locations.
#'
#' @param sites A data.frame with an ID and sfc_Point geometry containing site locations.
#' @param gdd_raster A raster containing growing degree days.
#' @return A tibble with growing degree days for each ID.
#' @importFrom magrittr `%<>%` `%>%`
#' @export
extract_GDD <- 
  function(gdd_raster, sites) {

    # Get annual accumulated growing degree days.
    terra::extract(x = gdd_raster,
                    y = sites) %>%
      dplyr::bind_cols(LabID = sites$LabID, GDD = .)
    
  }
