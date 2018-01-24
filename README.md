
<!-- README.md is generated from README.Rmd. Please edit that file -->
distancetocoast
===============

The goal of distancetocoast is to provide an easy lookup for the "distance to coastline" for longitude and latitude coordinates.

Use at your own risk!

Installation
------------

The distancetocoast package may be installed from Github using devtools.

``` r
devtools::install_github("mdsumner/distancetocoast")
```

Example
-------

There is an in-built data set, in `raster` format. The raster package includes an `extract` function which will look up a cell value at a given longitude and latitude location.

This value is the distance to the coastline from the centre of the cell.

``` r
library(distancetocoast)
library(raster)
#> Loading required package: sp
## beware of clashing with tidyr::extract
raster::extract(distance_to_coastline_lowres, cbind(147, -42))
#>       
#> 65628
```

This is a very approximate value, and it will depend on the content and quality of the coastline data used, on the resolution of the grid itself, some un-quantified local distortions due to coordinate transformations and discretization, and may not be accurate for some applications.

There will be some regions inside oceans, inside land, and inside lakes as defined by the coastline. We make no distinction for "inside" anything, this is purely distance to the line. A matching "land mask" layer could be added to provide a flag for these regions, but this is a deep can of worms ...

This grid was created by process it in tiles, reprojecting the coastline and the grid pixel centres to a local Lambert Azimuthal Equidistant projection (`aeqd` in [http://proj4.org/projections/aeqd.html](PROJ.4) terms) and calculating shortest Cartesian distance to the coastline coordinate in that projection. (We used the `nabor` package).

``` r
plot(distance_to_coastline_lowres, col = viridis::viridis(64))
plot(rnaturalearth::ne_coastline(), add = TRUE)
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" /> The in-built data can be interrogated directly for its properties.

``` r
## resolution (cell size in native coordinates)
raster::res(distance_to_coastline_lowres)
#> [1] 0.5 0.5

## dimensions (number of columns and rows)
dim(distance_to_coastline_lowres)
#> [1] 360 720   1

## the extent, in native coordinates
raster::extent(distance_to_coastline_lowres)
#> class       : Extent 
#> xmin        : -180 
#> xmax        : 180 
#> ymin        : -90 
#> ymax        : 90

## the "CRS", coordinate reference system (the map projection)
raster::projection(distance_to_coastline_lowres)
#> [1] "+init=epsg:4326 +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

## the range of values (distance in metres)
cellStats(distance_to_coastline_lowres, min)
#> [1] 1
cellStats(distance_to_coastline_lowres, max)
#> [1] 5297879
```

All of this information may be seen in one step by using the print method.

``` r
distance_to_coastline_lowres
#> class       : RasterLayer 
#> dimensions  : 360, 720, 259200  (nrow, ncol, ncell)
#> resolution  : 0.5, 0.5  (x, y)
#> extent      : -180, 180, -90, 90  (xmin, xmax, ymin, ymax)
#> coord. ref. : +init=epsg:4326 +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 
#> data source : in memory
#> names       : layer 
#> values      : 1, 5297879  (min, max)
```

The distance values are currently

See '/data-raw/' for the code used to produce this layer.

Development
-----------

We hope to add more data sets with a wider choice of methods so that an appropriate choice can be made for specific applications.

Fun
---

For a bit of fun, let's plot as a globe (might not work on Github, but easy enough to run locally).

``` r
library(quadmesh)
library(rgl)
library(proj4)

to_globe <- function(x, fact = 12) {
  if (fact > 1) x <- raster::aggregate(distance_to_coastline_lowres, fact = fact)
  qm <- quadmesh(x)
  v <- proj4::ptransform( t(qm$vb[1:3, ]) * pi/180, 
                          raster::projection(x), 
                         "+proj=geocent +datum=WGS84")
  qm$vb[1:3, ] <- t(v)
  scl <- function(x) {rg <- range(x, na.rm = TRUE);(x - rg[1])/diff(rg)}

  qm$material <- list(color = rep(viridis::viridis(64L)[scl(raster::values(x)) * 63L + 1], each = 4))
  qm
}
globe <- to_globe(distance_to_coastline_lowres, fact = 4)
rgl::rgl.clear()
rgl::shade3d(globe, specular = "black")

library(tidyverse)
#> ── Attaching packages ────────────────────── tidyverse 1.2.1 ──
#> ✔ ggplot2 2.2.1.9000     ✔ purrr   0.2.4     
#> ✔ tibble  1.4.2          ✔ dplyr   0.7.4     
#> ✔ tidyr   0.7.2          ✔ stringr 1.2.0     
#> ✔ readr   1.1.1          ✔ forcats 0.2.0
#> ── Conflicts ───────────────────────── tidyverse_conflicts() ──
#> ✖ ggplot2::calc()  masks raster::calc()
#> ✖ tidyr::extract() masks raster::extract()
#> ✖ dplyr::filter()  masks stats::filter()
#> ✖ dplyr::lag()     masks stats::lag()
#> ✖ dplyr::select()  masks raster::select()
library(spbabel)
rbind_na <- function(x) rbind(x, NA)
mk_lines <- function(x) {
  mat <- spbabel::sptable(x) %>% 
    split(.$branch_) %>% 
    purrr::map_df(rbind_na) %>% 
    dplyr::select(x_, y_) %>%   dplyr::slice(-1) %>% as.matrix()
    as_tibble(proj4::ptransform( as.matrix(mat) * pi/180, 
                          raster::projection(x), 
                         "+proj=geocent +datum=WGS84"))
}
#rgl.clear()
rgl::lines3d(mk_lines(rnaturalearth::ne_coastline()), col = "black", lwd = 3)
#rgl::rglwidget()
#rgl::rgl.snapshot("man/figures/globe1.png")
```

![globe distance](man/figures/globe1.png)

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
