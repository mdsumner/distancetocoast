d <- SOmap::SOmap_data$ant_coast_land

library(raster)
library(sf)
library(spbabel)
library(dplyr)
library(nabor)
library(raadtools)
coast_pts <- sptable(d) %>% distinct(x_, y_) %>% as.matrix()

rema <- readtopo("rema_1km")

#r <- raster::raster(extent(-180, 180, -90, 90), ncols = 720, nrows = 360, crs = "+init=epsg:4326")


# ## tile up
#tiles <- raster(extent(-180, 180, -90, 90), ncols = 60, nrows = 30, crs = "+init=epsg:4326")
tiles <- raster(extent(rema), ncols = ncol(rema)/50, nrows = nrow(rema)/50)
grid_pts <- coordinates(rema)
 tib <- tibble::tibble(native_cell = seq_len(ncell(rema)),
                       tile_cell = cellFromXY(tiles, grid_pts))
#distance <- list(cell = vector("list", ncell(tiles)),
#                 distance = vector("list", ncell(tiles)))
 ## process tiles in local projection
local_proj <- function(xy) {
   sprintf("+proj=aeqd +lon_0=%f +lat_0=%f +datum=WGS84", xy[1], xy[2])
}
#

dofun <- function(icell) {
   asub <- tib$tile_cell == icell
   tile <- dplyr::filter(tib, asub)
   lproj <- local_proj(reproj::reproj(xyFromCell(tiles, icell), source = projection(d), target = 4326)[,1:2])
   nn <- nabor::WKNND(reproj::reproj(coast_pts, lproj, source = projection(d))[,1:2])
   tile_pts <- reproj::reproj(xyFromCell(rema, tile$native_cell), lproj, source = projection(rema))[,1:2]
#  #plot(rgdal::project(coast_pts, lproj))
#  #points(tile_pts, pch = ".", col = "yellow")
   nearest_idx <- nn$query( tile_pts, k = 1, eps = 0, radius = 0)
   list(distance = nearest_idx$nn.dists[,1],
        cell = tile$native_cell)
 #  if (icell %% 100 == 0) print(icell)
}
library(furrr)
plan(multicore)
distance <- furrr::future_map(1:ncell(tiles), dofun)

 dd <- bind_rows(lapply(distance, as_tibble))
 tib <- inner_join(tib, dd, c("native_cell" = "cell"))
 dt <- setValues(rema, as.integer(tib$distance))
#plot(dt)
writeRaster(dt, "rema_distcoast_1km.tif")
#
# usethis::use_data(distance_to_coastline_lowres)
#
