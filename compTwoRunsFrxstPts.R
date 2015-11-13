suppressPackageStartupMessages(library(rwrfhydro))
options(warn=1)

args <- commandArgs(TRUE)

## arg 1: huc
runDir1 <- args[1]
runDir2 <- args[2]
if(is.na(runDir1) | is.na(runDir2)) {
  cat("Two 'runDir's are required\n")
  q(status=1)
}


frxstFile1 <- list.files(runDir1, pattern='frxst_pts_out.txt', full=TRUE)
if(!length(frxstFile1))
  frxstFile1 <- list.files(paste0(runDir1,'/VERIFICATION'), pattern='frxst_pts_out.txt', full=TRUE)
if(length(frxstFile1)) {
  frxst1 <- ReadFrxstPts(frxstFile1)
  frxst1$run <- basename(runDir1)
} else {
  cat("No frxst_pts_out.txt found in runDir: ",runDir1,"\n")
  q(status=1)
}

frxstFile2 <- list.files(runDir2, pattern='frxst_pts_out.txt', full=TRUE)
if(!length(frxstFile2))
  frxstFile2 <- list.files(paste0(runDir2,'/VERIFICATION'), pattern='frxst_pts_out.txt', full=TRUE)
if(length(frxstFile2)) {
  frxst2 <- ReadFrxstPts(frxstFile2)
  frxst2$run <- basename(runDir2)
} else {
  cat("No frxst_pts_out.txt found in runDir: ",runDir2,"\n")
  q(status=1)
}


suppressPackageStartupMessages(library(ggplot2))
outFile <- '~/compTwoRunsFrxstPts.pdf'
pdf(outFile, width=15, height=11)
try(
    print(
          ggplot() +
          geom_line(data=frxst1, aes(x=POSIXct, y=q_cms, color=run, group=st_id)) +
          geom_line(data=frxst2, aes(x=POSIXct, y=q_cms, color=run, group=st_id)) +
          theme_bw(base_size=21)
          )
    )
dev.off()

q(status=0)
