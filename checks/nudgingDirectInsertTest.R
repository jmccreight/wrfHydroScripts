suppressPackageStartupMessages(library(rwrfhydro))
options(warn=1)
## NOTE that right now the first time in the modeled timeseries is dropped:
## this is correct for cold starts. We could distinguish between restarts
# and cold starts?

## arguments are
## 1) runDir
## 2) OPTIONAL nCores, default=1, if > 1 runs in parallel using doMC
## 3) OPTIONAL mkPlot, default=FALSE. Only summary stats are printed. 
args <- commandArgs(TRUE)

## arg 1: huc
runDir <- args[1]
if(is.na(runDir)) {
  cat("First argument 'runDir' is required\n")
  q(status=1)
}

## arg 2: inPath
nCores <- as.integer(args[2])
if(is.na(nCores)) nCores <- 1
## setup multicore
if(nCores > 1) {
  suppressPackageStartupMessages(library(doMC))
  registerDoMC(nCores)
}

## arg 2: outPath
mkPlot <- as.logical(args[3]) ## this can give NA as logical!
if(is.na(mkPlot) | class(mkPlot)!='logical') mkPlot <- FALSE

## does run dir exist?
if(!file.exists(runDir)) {
  cat("rundir: ", runDir, ' does not exist. Exiting.\n')
  q(status=1)
}

## distinguish between cold starts and restarts?

## For direct insertion with current temporal weighting function, 
## tau has to be less than NOAH timestep. Can we test if that's true?
## Bring in tau from nudgingParams.nc and compare to NOAH_TIMESTEP in namelist.hrldas.

CheckDirectInsert <- function(runDir, parallel=FALSE) {

  ## identify if frxst pts exists
  frxstFile <- list.files(runDir, pattern='frxst_pts_out.txt', full=TRUE)
  if(!length(frxstFile))
    frxstFile <- list.files(paste0(runDir,'/VERIFICATION'), pattern='frxst_pts_out.txt', full=TRUE)
  if(length(frxstFile)) {
    modelDf <- ReadFrxstPts(frxstFile)
  } else {
  ## if not frxst_pts use CHRTOUT_DOMAIN
    warning('not yet configured use of CHRTOUT_DOMAIN files', .immediate=TRUE)
    ## ... deeal with this later.
    ## dont forget the time offest in the name of the file.
    ## loop through the stations, pulling each from the file individually?
  }
  
  ## identify the observations
  obsFiles <- list.files(paste0(runDir,'/nudgingTimeSliceObs'),
                         pattern='.15min.usgsTimeSlice.ncdf', full=TRUE)
  obsTimes <- as.POSIXct(substr(basename(obsFiles),1,19),
                         format='%Y-%m-%d_%H:%M:%S', tz='UTC')
  ## strictly greater is correct for cold start runs as DA is not applied at the
  ## initial time.
  whObsInModel <- which(obsTimes > min(modelDf$POSIXct) &
                        obsTimes <= max(modelDf$POSIXct) )
  obsDf <- plyr::ldply(obsFiles[whObsInModel], ReadNcTimeSlice, .parallel=parallel)

  ## match the obs to the model  
  ## 1) throw out obs which are not on the model times
  obsDf <- subset(obsDf, dateTime %in% modelDf$POSIXct)
  ## 2) Throw out stations from the model which are not in the obs
  modelDf <- subset(modelDf, trimws(st_id) %in% trimws(obsDf$site_no))
  ## 3) Throw out stations from the obs which are not in the model
  obsDf <- subset(obsDf, trimws(site_no) %in% trimws(modelDf$st_id))
  ## a check: intersect(trimws(obsDf$site_no), trimws(modelDf$st_id))
  ## 4) prepare for merging: standardize the time and site variables
  names(obsDf)[which(names(obsDf)=='dateTime')] <- 'POSIXct'
  names(obsDf)[which(names(obsDf)=='site_no')] <- 'st_id'
  modelDf$st_id <- trimws(modelDf$st_id)
  obsDf$st_id <- trimws(obsDf$st_id)
  names(modelDf)[which(names(modelDf)=='q_cms')] <- 'discharge.cms'
  obsDf$kind <- 'obs'
  modelDf$kind <- 'model'
  
  ## 6
  theCols <- c('POSIXct','st_id','discharge.cms','kind')
  comboDf <- rbind(obsDf[,theCols], modelDf[,theCols])

  ## pair
  ExtractPair <- function(dd) {
    if(nrow(dd) != 2) return(NULL)
    if(!(all(c("obs","model") %in% dd$kind))) {
      warning("repeats?")
      NULL
    }
    data.frame(POSIXct=dd$POSIXct[1],
               st_id=dd$st_id[1],
               obs=dd$discharge.cms[which(dd$kind=='obs')],
               model=dd$discharge.cms[which(dd$kind=='model')])
  }
  pairDf <- plyr::ddply(comboDf, plyr::.(st_id, POSIXct), ExtractPair, .parallel=parallel)
  pairDf$err <- pairDf$model - pairDf$obs
  pairDf
}

## get the data
pairDf <- CheckDirectInsert(runDir, parallel=nCores > 1)

cat("\nThe number of observations nudged: ", nrow(pairDf),'\n')
cat("Quantiles of modeled-observed (errors) for nudging:\n")
quantile(pairDf$err, seq(0,1,.1))

if(mkPlot) {
  ## check if the rundir is write protected, write it to ~ if it is.
  suppressPackageStartupMessages(library(ggplot2))
  ggplot(pairDf, aes(x=POSIXct, y=err, color=st_id)) + geom_line()
  ggplot(pairDf, aes(x=err)) + geom_histogram()
}

retValue <- if(any(abs(pairDf$err)>.001)) 1 else 0

q(status=retValue)
