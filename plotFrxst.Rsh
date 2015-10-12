#!/opt/R-3.2/bin/Rscript 
####!/opt/R/bin/Rscript
## arguments are
## 1: path: defaults to paste0(getwd(),'/frxst_pts_out.txt')

options(warn=1)
args <- commandArgs(TRUE)
## arg 1: huc
path <- args[1]
if(is.na(path)) path <- paste0(getwd(),'/frxst_pts_out.txt')
if(dir.exists(path)) path <- paste0(path,'/frxst_pts_out.txt')
cat(paste0(path,'\n'))
outFile <- paste0(dirname(path),'/frxst_pts_PLOT.png')

if(file.exists(path)) {
    suppressPackageStartupMessages(library(rwrfhydro))
    suppressPackageStartupMessages(library(ggplot2))
    cat(paste0('Input file: ',path,'\n'))
    frxst <- ReadFrxstPts(path)
    frxst <- subset(frxst, !is.na(frxst$q_cms))
    png(width=1500, height=900, file=outFile)
    print(
        ggplot(frxst,aes(x=POSIXct, y=q_cms, color=st_id)) +
            geom_line()  +
            scale_color_discrete(guide='none') +
            scale_x_datetime(name='') +
            ggtitle(path) +
            theme_bw(base_size=24)
         )
    invisible(dev.off())
}

if(file.exists(outFile)) {
  cat(paste0('Output: ',outFile,'\n'))
  q(status=0)
} else {
  cat("Plot failed\n")
  q(status=1)
}

