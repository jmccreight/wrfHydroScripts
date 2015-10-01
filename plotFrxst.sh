#!/bin/bash

#Arguments
#1) The file or the path to a file containin a frxst_pts_out.txt file. 

if [ ! -e $1 ]
then
    echo "No such file: $1"
    exit 1
fi

IFS=$'\n'
blather=`~jamesmcc/wrfHydroScripts/plotFrxst.Rsh $1`
retR=$?
if [ ! $retR -eq 0 ]
then
    echo "R failed to generate output file"
    exit 1
fi
plotFile=`echo -e "$blather" | grep -i output | cut -d ' ' -f2`
echo $plotFile
display $plotFile &

exit 1
