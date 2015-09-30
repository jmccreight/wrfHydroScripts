#!/bin/bash

help='

cleanRun.sh :: help

Purpose: clean up WRF-Hydro output in the current directory and 
start a new run. Optionally create/cleanup a specified directory
and run there. ASSUMES that the model is wrf_hydro.exe in calling
directory.

Options:
  Those taken by linkToTestCase. Passed to if when the optional
  second argument is used to establish a run directory.        

Arguments:
 1) The number of mpi tasks (processors)
 2) OPTIONAL A directory for the run. This ASSUMES the script
      is called from a run directory. NOTE THAT THIS CAN BECOME
      A MESS IF DIRECTORIES ABOVE THE RUN DIRECTORY ARE REFERENCED 
      IN THE NAMELIST. The suggestion is to have all namelist 
      dependencies in ./ instead of ../ which can be achieved 
      by symlinking ../dep to ./dep. The intent of creating run 
      directories here is so that multiple runs can be happening 
      simultaneously for the same domain.

Note:
There is a special section to detect the correct build of mpi, 
 which is likely to cause others issues at some point. 

'


## options are just passed to linkToTestCase.sh 
## Wish there were an easier way to do this other than copy the code.
cOpt=''
uOpt=''
nOpt=''
pOpt=''
while getopts ":ucnp" opt; do
  case $opt in
    u)
      uOpt="-u"
      ;;
    c)
      cOpt="-c"
      ;;
    n)
      nOpt="-n"
      ;;
    p)
      pOpt="-p"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

numProc=`nproc`
numProc=`echo "$numProc/2" | bc`

useIfort=`ldd wrf_hydro.exe | grep ifort | wc -l`
if [ "$useIfort" -gt 0 ] 
then
    MPIRUN=/opt/openmpi-1.10.0-intel/bin/mpirun
else
    MPIRUN=mpirun
fi


## first argument is required: the number of mpi tasks
if [ ! -z "$1" ]
then
    nMpiTasks=$1
    if [ ! "$nMpiTasks" -gt 0 ] && [ ! "$nMpiTasks" -le "$numProc" ] 
    then
        echo 'Unacceptable value for number of processors.'
        echo "Please use a value in 1-${numProc}"
        echo "(Script currently assumes a multithreading which reports"
        echo " actual number of processors*2, may need change for your machine."
        exit 1
    fi
else 
    echo "Please specify the number of mpi tasks mpirun"
    echo $help
    exit 1
fi

## second argument is optional: a run directory
if [ ! -z "$2" ]
then
    runDir=$2
    if [ ! -d $runDir ]; then  mkdir -p $runDir; fi
    ~jamesmcc/wrfHydroScripts/linkToTestCase.sh \
        $cOpt $uOpt $nOpt $pOpt . `pwd` `pwd`/$runDir
    origDir=`pwd`
    cd $runDir
    if [ "$cOpt" == "-c" ]
    then
        cp $origDir/wrf_hydro.exe .
    else
        ln -sf $origDir/wrf_hydro.exe .
    fi
fi

~jamesmcc/wrfHydroScripts/cleanup.sh

$MPIRUN -np $nMpiTasks ./wrf_hydro.exe
mpiReturn=$?
echo -e "\e[36mReturn code: $mpiReturn\e[0m"
exit $mpiReturn


exit 0
