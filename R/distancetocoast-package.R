#' @keywords internal
"_PACKAGE"

#' Distance to coast (varying resolutions)
#'
#' All are `RasterLayer` layer with the distance (metres) to the Natural Earth
#' coastline.
#' To find the dimensions, extent, resolution, data properties, and metadata
#' use the raster package functions - most of this information will be printed by default.
#' \itemize{
#' \item `distance_to_coastline_lowres`  Scale 110  `rnaturalearth::ne_coastline(scale = 110)`.
#' \item `distance_to_coastline_50`  Scale 50 `rnaturalearth::ne_coastline(scale = 50)`.
#' \item `distance_to_coastline_10`  Scale 10  `rnaturalearth::ne_coastline(scale = 110)`.
#' }
#' @docType data
#' @name distance_to_coastline_lowres
#' @aliases distance_to_coastline_50 distance_to_coastline_10
NULL
