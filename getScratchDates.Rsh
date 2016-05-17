#!/glade/apps/opt/r/3.2.5/bld_intel/bin/Rscript
##/glade/apps/opt/r/3.2.2/intel/16.0.0/bin/Rscript
# the  above path often needs customization.

## Scripts arguments are
## 1: olderThan
## 2: searchstring

## When we want to start calling more functions, we could make this a more general
## interface where we supply file names and then the name of the function and 
## followed by its arguments. 

## Avoid doing this for now.
#library(rwrfhydro)

args <- commandArgs(TRUE)
nDays <- args[1]
searchStr   <- args[2]

if(is.na(nDays)) nDays <- 44
if(is.na(searchStr)) searchStr <- '*'

procTime <- system.time( {

  whoAmI <- system('whoami', intern=TRUE)
  findStr <- paste0('find -P /glade/scratch/',whoAmI,
                    ' -type f -iname "',searchStr,'" -atime +',nDays,
                    ' -printf "%A@ %p\n"')
  print(findStr)
  theFind <- system(findStr,intern=TRUE)

  if(length(theFind)) {
    theFind <- matrix(unlist(strsplit(theFind,'\\ ')), ncol=2, byrow=TRUE)
    nowSinceDatum <- system('date +%s', intern=TRUE)
    daysOld <- (as.numeric(nowSinceDatum)-as.numeric(theFind[,1]))/(60*60*24)
    
    nFiles <- nrow(theFind)
    ## 750 seemed like a save number of files to pass b/c 1500 worked.
    fileSize <- c()
    chunkSize <- 750
    for(cc in 0:(nFiles %/% chunkSize)) {
      fileSizeStr <- paste0('ls -lh ',
                            paste(theFind[(chunkSize*(cc)+1):min(nFiles, chunkSize*(cc+1)),2], collapse=' '),
                            ' | tr -s " " | cut -d" " -f5')
      fileSize <- c(fileSize, system(fileSizeStr, intern=TRUE))
    }
    
    sortOrd <- sort(daysOld, decreasing=TRUE, index.return=TRUE)$ix
    sortedInfo=paste(ceiling(daysOld[sortOrd]), fileSize[sortOrd], theFind[sortOrd,2], sep= ' ')

  } else {
    sortedInfo=paste0('# < No files found older than ', nDays,' days. >')
  }
    
})

sortedInfo <-
    c(paste0("# Report for user: ",whoAmI),
      paste0('# ',format(Sys.time())),
      paste0('# Time taken ~',as.numeric(procTime['elapsed'])),
      paste0("# Checking for files older than ",nDays," days."),
      '#',
      '# Days Size File  (Oldest ->',
      '#  Old                Newest)',
      '#------------------------------------------------------------------------------',
      sortedInfo)

  
  write(sortedInfo, file = paste0("/glade/scratch/",whoAmI,'/scratchDates.txt'))
  
