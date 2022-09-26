#' @name extract_earliest_crop
#' @title Extract earliest date for a crop by province
#'
#' @description `extract_earliest_crop()` extracts the sample with the earliest date for a crop by province.
#'
#' @param database A data.frame containing the crop database.
#' @return A tibble that contains the earliest date for each province.
#' @importFrom magrittr `%<>%` `%>%`
#' @export
extract_earliest_crop <-
  function(database) {
    database %>%
      dplyr::group_by(Province) %>%
      dplyr::slice_max(MedianBP) %>%
      dplyr::ungroup() %>% 
      dplyr::arrange(Latitude)
    
  }