##clean working space
rm(list = ls())

##set your directory
setwd('C:/Users/mmazzamu/OneDrive - University of Wyoming/Desktop/Università/teaching/RLadies')

##read data
#install.packages('readxl')
library(readxl)

cameras <- as.data.frame(read_excel("occu_prep.xlsx", sheet = "loc"))#sheet with operational info

mydata <- as.data.frame(read_excel("occu_prep.xlsx", sheet = "det"))#sheet with detections
mydata$DateTimeOriginal <- as.POSIXct(mydata$DateTimeOriginal, timeZone ="Asia/Kuala_Lumpur")

##create report for your data
#install.packages('camtrapR')
library(camtrapR)

#first we create a camera trap station operability matrix
cameraop <- cameraOperation(CTtable      = cameras,
                            stationCol   = "SiteName",
                            setupCol     = "StartDate",
                            retrievalCol = "EndDate",
                            writecsv     = FALSE,
                            hasProblems  = FALSE,#if some cameras did not work for some days change in TRUE and add to your dataframe columns "Problem1_from" and "Problem1_to"
                            dateFormat   = "ymd")


#create a report about a camera trapping survey and species detections
report <- surveyReport (recordTable          = mydata,
                        CTtable              = cameras,
                        camOp                = cameraop,
                        speciesCol           = "Species",
                        stationCol           = "SiteName",
                        setupCol             = "StartDate",
                        retrievalCol         = "EndDate",
                        CTDateFormat         = "ymd", 
                        recordDateTimeCol    = "DateTimeOriginal",#always name it like this for some functions that require it
                        recordDateTimeFormat = "ymd HMS",
                        Xcol                 ="X",
                        Ycol                 ="Y",
                        sinkpath             =getwd() #the report will be save in your directory
                        )

report[[1]]# camera trap operation times and image date ranges
report[[2]]# number of species by station
report[[3]]# number of events and number of stations by species
report[[4]]# number of species events by station
report[[5]]# number of species events by station including 0s (non-observed species)


##prepare your data for occupancy analysis

##standardize covariates
cameras[, 8:17] = scale(cameras[, 8:17])
##prepare covariates for analysis
covs <- cameras[, 8:18]
row.names(covs)<- cameras$SiteName


##create your detection history (here we use a 7 day resolution)
#install.packages('unmarked')
library(unmarked)

DetHist <- detectionHistory(recordTable          = mydata, 
                            species              = "Red Deer", 
                            camOp                = cameraop, 
                            stationCol           = "SiteName", 
                            speciesCol           = "Species", 
                            recordDateTimeCol    = "DateTimeOriginal",
                            occasionLength       = 7, 
                            day1                 = "station",
                            datesAsOccasionNames = FALSE,
                            includeEffort        = TRUE,
                            scaleEffort          = FALSE,
                            timeZone             = "Asia/Kuala_Lumpur",
                            writecsv             = TRUE,
                            outDir               =getwd()
                            )

##let's look at the list created
DetHist[[1]]
DetHist[[2]]


##Organize detection, non-detection data along with the covariates 
um<-unmarkedFrameOccu(y=DetHist[[1]],siteCovs=covs)
um #look at your data

#summary(um) it makes sense to look at it if you do not standardize covs
