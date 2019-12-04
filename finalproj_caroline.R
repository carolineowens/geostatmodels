#####################################
### Setup, read and clean data ######
#####################################

#required packages

library(tidyverse)
library(RandomFields)
library(geoR)
library(convoSPAT)
library(StatMatch)

#read data

sj <- read.csv("G:/Shared drives/PSTAT-Geospatial_Model_Selection/Data/SJrb_cleaned.csv")
tm <- read.csv("G:/Shared drives/PSTAT-Geospatial_Model_Selection/Data/TMrb_cleaned.csv")

#remove extra columns, create temperature average
sj <- sj %>% 
  mutate(temp.avg = 0.5*(temp.min+temp.max)) %>% 
  select(-X, -temp.max, -temp.min)
View(sj)

tm <- tm %>%
  na.omit(water.content) %>% 
  mutate(temp.avg = 0.5*(temp.min+temp.max)) %>% 
  select(-X, -temp.max, -temp.min)
View(tm)

#create an overall dataset for both basins
dat <- bind_rows(sj, tm) %>% 
  transmute(basin = river.basin,
            SWE = water.content,
            elev = elev,
            lon = lon,
            lat = lat,
            snodep = snodep,
            asp = aspect,
            temp = temp.avg)

#####################################
### Build convolution model #########
#####################################

#create SPDF

sjxy <- dat %>% 
  filter(basin == "SAN JOAQUIN R") %>% 
  select(lon, lat)

sjdat <- dat %>% 
  filter(basin == "SAN JOAQUIN R") %>% 
  select(-basin)

sjspdf <- SpatialPointsDataFrame(coords = sjxy, data=data.frame(sjdat),
                                 proj4string = CRS("+proj=longlat +datum=WGS84"))

  
tmxy <- dat %>% 
  filter(basin == "TUOLUMNE R") %>% 
  select(lon, lat)

tmdat <- dat %>% 
  filter(basin == "TUOLUMNE R") %>% 
  select(-basin)

tmspdf <- SpatialPointsDataFrame(coords = tmxy, data=data.frame(tmdat),
                                 proj4string = CRS("+proj=longlat +datum=WGS84"))

#set number of clusters and centers
final <- kmeans(sjxy, 3, nstart = 25)
xymix <- final$centers

#fit spatial model using training data
NS1 <-NSconvo_fit(sp.SPDF = sjspdf,
                  cov.model = "exponential", 
                  mc.locations = xymix, 
                  fit.radius = .34, 
                  mean.model = (sjspdf$SWE ~ sjspdf$lon + sjspdf$elev))

#uncomment to predict test data using model
#must run predict.NSconvo function from Mark Risser's github

#pred <- predict.NSconvo(NS1, 
#                        pred.coords = as.matrix(tmxy), 
#                        pred.covariates = as.matrix(tmdat[,3:2])
#)
#
#pred

#####################################
### Simulate data from model ########
#####################################

# Objective: conduct simulation study to determine the optimal
# parameterization and the optimal model selection metric

N.obs <- 20^2 #set resolution of simulation

#Simulate data using the NS1 model parameterization
sim1 <- NSconvo_sim(grid = TRUE, 
           y.min = min(sjxy[,2]), y.max = max(sjxy[,2]), #fit within the extent of san joaquin
           x.min = min(sjxy[,1]), x.max = max(sjxy[,1]),
           N.obs = N.obs, #pulled the # obs from example in help file 
           sim.locations = NULL, 
           mc.kernels.obj = NULL, #use kernels from model instead 
           mc.kernels = NS1$mc.kernels, mc.locations = NS1$mc.locations, #specify kernel matrices and centers from NS1 model
           lambda.w = NS1$lambda.w, 
           tausq = NS1$tausq.est, 
           sigmasq = NS1$sigmasq.est, 
           beta.coefs = data.frame(NS1$beta.est),
           kappa = NS1$kappa, 
           covariates = data.frame(cbind(rep(1, N.obs), #Matrix with N.obs rows and columns matching number of beta.coefs (3) 
                                         rep(-119.07, N.obs), #covariate information for each of simulated values
                                         rep(8678.76, N.obs))), #is this just the x matrix?? here using means for each column
           cov.model = NS1$cov.model)

#extract simulated data for plotting
simdat <- data.frame(cbind(sim1$sim.locations[,1], sim1$sim.locations[,2], sim1$sim.data))
colnames(simdat) = c("simlon", "simlat", "simresp")

plot1 <- ggplot(data=simdat, aes(x= simlon, y=simlat, fill = simresp))+
  geom_tile()+
  theme_classic()

plot1 #this shows simulated SWE across a rectangular area that would contain San Joaquin basin
                
#####################################
### Using covariates in covariance ##
#####################################

# Following the methods of Schmidt et al. to use covariate method
# adding basin as a covariate in the covariance structure