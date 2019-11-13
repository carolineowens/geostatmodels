#script to import and work with TIFF data
# from https://www.earthdatascience.org/courses/earth-analytics/lidar-raster-data-r/introduction-to-spatial-metadata-r/

install.packages("raster")
library(raster)
install.packages("rgdal")
library(rgdal)

setwd("G:/Shared drives/PSTAT-Geospatial_Model_Selection")
#I downloaded some of the ASO data into the google drive

GDALinfo("135988930/ASO_3M_QF_USCOGM_20170221.tif")
#this allows you to view the spatial metadata of the TIFF file

dat1 <- raster("135988930/ASO_3M_QF_USCOGM_20170221.tif")
#import the data as a raster layer

crs(dat1)
#view coordinate reference system of the data - here WGS84

dat1@extent
#view spatial extent via the slot (not sure what slot means)

nlayers(dat1)
#shows how many layers/bands the dataset has - here, 1

plot(dat1) #visualize the layer
