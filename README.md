# ENSO_Maize_Impacts: ENSO Impacts on Maize Agriculture in the Southwestern United States

`ENSO_Maize_Impacts` is an *R* package implementing functions to perform
analysis on the relationship between maize agriculture and temperature changes in prehistory.

This is the official R package for [ENSO_Maize_Impacts](https://github.com/Archaeo-Programmer/ENSO_Maize_Impacts), 
which contains all code associated with the analyses described and presented, including figures and tables, in Gillreath-Brown et al. 2022 (submitted): 

Gillreath-Brown, A., R. K. Bocinsky, and T. A. Kohler (2022). Children of El Niño: How Maize Farmers in the US Southwest Grew and Prospered under El Niño but suffered under La Niña. Submitted to *Kiva* for review.
    
All code for analysis and reconstruction is in [Maize_Analysis.Rmd](vignettes/Maize_Analysis.Rmd) and all code for figures and tables is in [Maize_Figures.Rmd](vignettes/Maize_Figures.Rmd).

## Installation

You can install `ENSO_Maize_Impacts` from GitHub with these lines of R code (Windows users are recommended to install a separate program, Rtools, before proceeding with this step):

``` r
if (!require("devtools")) install.packages("devtools")
devtools::install_github("Archaeo-Programmer/ENSO_Maize_Impacts")
```

## Repository Contents

The [:file\_folder: vignettes](vignettes) directory contains:
