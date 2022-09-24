#' @name extract_diffusion
#' @title Extract the Latitudinal Diffusion of a Crop
#'
#' @description Extract the diffusion of a crop by northern latitude
#'
#' @param database A data.frame containing the crop database.
#' @param direction A string stating the direction (i.e., north).
#' @return A tibble that has the frontier of a crop through time using 100 year time bins.
#' @importFrom magrittr `%<>%` `%>%`
#' @export
extract_diffusion <-
  function(database, direction = c("north")) {
    database <- database %>%
      # Create 100 year bins.
      dplyr::mutate(bin = cut(
        MedianBP,
        breaks = seq(
          plyr::round_any(min(MedianBP), 100, f = floor),
          plyr::round_any(max(MedianBP), 100, f = ceiling),
          by = 100
        ),
        include.lowest = TRUE
      ))
    
    if (direction == "north")
      database %>%
      dplyr::group_by(bin) %>%
      dplyr::slice_max(Lat) %>%
      dplyr::slice_max(MedianBP) %>%
      dplyr::ungroup() %>%
      dplyr::arrange(desc(MedianBP)) %>%
      dplyr::filter(Lat == cummax(Lat)) %>%
      dplyr::group_by(SiteName) %>%
      dplyr::slice_min(Date, with_ties = FALSE) %>%
      dplyr::ungroup() %>% 
      dplyr::arrange(Date)
    else
      stop(
        "The direction is not north. Please use north for direction. We will be updating this function in the fugure to do other directions."
      )
  }