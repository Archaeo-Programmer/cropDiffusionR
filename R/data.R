#' Annual Accumulated Growing Degree Days from SAGE.
#'
#' A `raster` containing annual global accumulated growing degree days for the year with a base temperature of 5°C.
#'
#' @format An object of class `RasterLayer`.
#' @source \url{https://sage.nelson.wisc.edu/data-and-models/atlas-of-the-biosphere/mapping-the-biosphere/ecosystems/growing-degree-days/}
"global_gdd"

#' North American Southwest Ancient Maize Database.
#'
#' A `tibble` containing calibrated radiocarbon data for ancient maize macrosamples across the North American Southwest.
#'
#' @format An object of class `tibble`.
#' @source \url{https://doi.org/10.1038/s41597-022-01118-7}
#' @source \url{https://doi.org/10.48512/XCV8459173}
#' @source \url{http://en.ancientmaize.com/}
#' @source \url{https://www.canadianarchaeology.ca/}
#' @references
#' Bocinsky, R. Kyle, Darcy Bird, and Erick Robinson, (2020). Compendium of R code and data for p3k14c: A synthetic global database of archaeological radiocarbon dates. Accessed on September 12, 2022. https://github.com/people3k/p3k14c
#'
#' Bird, D., Miranda, L., Vander Linden, M. et al. p3k14c, a synthetic global database of archaeological radiocarbon dates. Sci Data 9, 27 (2022). https://doi.org/10.1038/s41597-022-01118-7
#' 
#' Blake, M., B. Benz, D. Moreiras, L. Masur, N. Jakobsen and R. Wallace. 2017. Ancient Maize Map, Version 2.1: An Online Database and Mapping Program for Studying the Archaeology of Maize in the Americas. http://en.ancientmaize.com/. Laboratory of Archaeology, University of B.C., Vancouver. Accessed on February 24, 2021.
#' 
#' Martindale, Andrew, Richard Morlan, Matthew Betts, Michael Blake, Konrad Gajewski, Michelle Chaput, Andrew Mason, and Pierre Vermeersch (2016) Canadian Archaeological Radiocarbon Database (CARD 2.1), accessed September 10, 2022.
"maizeDB"

#' Annual Accumulated Growing Degree Days from WorldClim.
#'
#' A `raster` containing annual accumulated growing degree days for the year with a base temperature of 10°C and maximum temperature of 30°C. 
#' GDD was calculated from tmin and max 30 seconds (~1 \ifelse{html}{\out{km<sup>2</sup>}}{\eqn{km^2}}).
#'
#' @format An object of class `RasterLayer`.
#' @source \url{https://www.worldclim.org/data/worldclim21.html}
"WorldClim_annual_gdd"

#' Southwestern United States and Mexico States Polygon.
#'
#' A `MULTIPOLYGON` containing the state boundaries for the southwestern United States (i.e., Arizona, Colorado, New Mexico, and Utah) and Mexico.
#'
#' @format An object of class `sfc_MULTIPOLYGON`.
#' @source \url{https://www.arcgis.com/home/item.html?id=ac9041c51b5c49c683fbfec61dc03ba8}
"usa_mexico_states"

#' Digital Elevation Model for the Southwestern United States and Mexico States.
#'
#' A `raster` containing elevation for the southwestern United States (i.e., Arizona, Colorado, New Mexico, and Utah) and Mexico.
#'
#' @format An object of class `RasterLayer`.
#' @source \url{https://github.com/jhollist/elevatr}
"NASW_elevation"

