library(magrittr)

# Accumulated growing degree days for the year with a base temperature of 5 degrees Celsius.
# Data was downloaded from https://sage.nelson.wisc.edu/data-and-models/atlas-of-the-biosphere/mapping-the-biosphere/ecosystems/growing-degree-days/,
# then was convert to a raster from a ArcGIS format. 
global_gdd <- raster::raster(here::here("data-raw/gdd1.tif"))

usethis::use_data(global_gdd,
                  overwrite = TRUE)