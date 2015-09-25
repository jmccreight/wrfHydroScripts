#!/bin/bash

## Purpose: clean up WRF-Hydro input in the current directory and 
## start a new run. 
## There is a special section to detect the correct build of mpi, 
## which is likely to cause others issues at some point. 

./cleanup.sh

numProc=`nproc`
numProc=`echo "$numProc/2" | bc`

useIfort=`ldd wrf_hydro.current.exe | grep ifort | wc -l`
if [ "$useIfort" -gt 0 ] 
then
    MPIRUN=/opt/openmpi-1.10.0-intel/bin/mpirun
else
    MPIRUN=mpirun
fi


if [ ! -z "$1" ]
then
    if [ "$1" -gt 0 ] && [ "$1" -le "$numProc" ] 
    then
        $MPIRUN -np $1 ./wrf_hydro.current.exe
        mpiReturn=$?
        echo -e "\e[36mReturn code: $mpiReturn\e[0m"
        exit $mpiReturn
    else
        echo 'unacceptable value for number of processors'
        exit 1
    fi
else 
    echo "Please specify the number of processors for mpirun"
    exit 1
fi


exit 0
