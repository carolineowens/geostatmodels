#script to import and work with TIFF data

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

