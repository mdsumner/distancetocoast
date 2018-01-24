#library(rnaturalearthhires)
d <- rnaturalearth::ne_coastline(scale = 10, returnclass = "sf")

library(raster)
library(sf)
library(spbabel)
library(dplyr)
library(nabor)
coast_pts <- sptable(d) %>% distinct(x_, y_) %>% as.matrix()
#coast <- st_union(d)
r <- raster::raster(extent(-180, 180, -90, 90),
                    ncols = 1620, nrows = 810,
                    crs = "+init=epsg:4326")


## tile up
tiles <- raster(extent(-180, 180, -90, 90),
                ncols = ncol(r)/10,
                nrows = nrow(r)/10, crs = "+init=epsg:4326")
grid_pts <- coordinates(r)
tib <- tibble::tibble(native_cell = seq_len(ncell(r)),
                      tile_cell = cellFromXY(tiles, grid_pts))
distance <- list(cell = vector("list", ncell(tiles)),
                 distance = vector("list", ncell(tiles)))

## process tiles in local projection
local_proj <- function(xy) {
  sprintf("+proj=aeqd +lon_0=%f +lat_0=%f +datum=WGS84", xy[1], xy[2])
}

for (icell in seq_len(ncell(tiles))) {
  asub <- tib$tile_cell == icell
  tile <- dplyr::filter(tib, asub)
  lproj <- local_proj(xyFromCell(tiles, icell))
  nn <- nabor::WKNND(rgdal::project(coast_pts, lproj))
  tile_pts <- rgdal::project(xyFromCell(r, tile$native_cell), lproj)
  #plot(rgdal::project(coast_pts, lproj))
  #points(tile_pts, pch = ".", col = "yellow")

  nearest_idx <- nn$query( tile_pts, k = 1, eps = 0)
  distance$distance[[icell]] <- nearest_idx$nn.dists[,1]
  distance$cell[[icell]] <- tile$native_cell
  if (icell %% 100 == 0) print(icell)
}
d <- as_tibble(lapply(distance, unlist))
tib <- inner_join(tib, d, c("native_cell" = "cell"))
distance_to_coastline_10 <- setValues(r, as.integer(tib$distance))

usethis::use_data(distance_to_coastline_10)

