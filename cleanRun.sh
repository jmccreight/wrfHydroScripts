#!/bin/bash

help="

cleanRun.sh :: help

Purpose: clean up WRF-Hydro output in the current directory and 
start a new run. Optionally create/cleanup a specified directory
and run there. ASSUMES that the model is wrf_hydro.exe in calling
directory.

Options:
  Those taken by cleanup (-r) and linkToTestCase (-fpunc). The later 
  are onlyPassed to linkToTestCase when the optional second argument 
  is used to establish a run directory.        

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
  3) OPTIONAL The binary to use, will be copied to run directory.

Note:
There is a special section to detect the correct build of mpi, 
 which is likely to cause others issues at some point. 

"

## options are just passed to linkToTestCase.sh 
## Wish there were an easier way to do this other than copy the code.
fOpt=''
pOpt=''
uOpt=''
nOpt=''
cOpt=''
dOpt=''
oOpt=''
rOpt=''
while getopts ":fpuncdor" opt; do
  case $opt in
    u)
      uOpt="-u"
      ;;
    c)
      cOpt="-c"
      ;;
    f)
      fOpt="-f"
      ;;
    d)
      dOpt="-d"
      ;;
    o)
      dOpt="-o"
      ;;
    n)
      nOpt="-n"
      ;;
    p)
      pOpt="-p"
      ;;
    r)
      rOpt="-r"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 

numProc=`nproc`
numProc=`echo "$numProc/2" | bc`

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
    echo "Please specify the number of mpi tasks mpirun. $help"
    exit 1
fi

## second and third arguments are optional: a run directory and/or a binary
## set a default (rather than complicated logic)
theBinary=wrf_hydro.exe
rundir=''
if [ ! -z "$2" ]
then
    ## was there a binary passed? Which argument?
    checkBinary=`ldd $2`
    if [ $? -eq 0 ] 
    then
        ## the second argument is the binary
        theBinary=$2
        if [ ! -z "$3" ]; then runDir=$3; fi
    else 
        ## if there's a third argument
        if [ ! -z "$3" ]    
        then 
            checkBinary=`ldd $3`
            if [ $? -eq 0 ]
            then 
                theBinary=$3 
            else
                echo -e "\e[31mNeither argument 2 nor 3 is a valid binary. Please check."
                exit 1
            fi
            runDir=$2
        fi
    fi
fi  


                   
## now deal with the run directory 
if [ ! -z $runDir ] 
then
    if [ ! -d $runDir ]
    then  
        mkdir -p $runDir
        if [ ! $? -eq 0 ]
        then 
            echo -e "\e[31mProblems creating run dir:\e[0m $runDir"
            exit 1
        fi
    fi

    ## clean up the run directory BEFORE linking to restarts
    origDir=`pwd`
    cd $runDir   
    $whsPath/cleanup.sh $rOpt
    cd $origDir

    ## setup the new run directory
    $whsPath/linkToTestCase.sh \
        $cOpt $fOpt $oOpt $dOpt $uOpt $nOpt $pOpt . `pwd` `pwd`/$runDir
    origDir=`pwd`
    cd $runDir
    ## always copy the binary
    cp $origDir/$theBinary .
else 
    $whsPath/cleanup.sh $rOpt
fi

## potentially different invocations of mpirun. 
## deal with host differences: put your flavor here
theHost=`hostname`

## YELLOWSTONE
if [[ $theHost == *"ys"* ]] 
then 
    echo "Running on yellowstone!"   
    mpirun.lsf ./$theBinary
fi

## HYDRO-C1
if [[ $theHost == *"hydro-c1"* ]] 
then 
    ## a check for the ifort versus the pg compiler
    useIfort=`ldd $theBinary | grep ifort | wc -l`
    if [ ! $? -eq 0 ] 
    then
        echo -e "\e[31mProblems with executable:\e[0m wrf_hydro.exe"
        exit 1
    fi
    if [ "$useIfort" -gt 0 ] 
    then
        echo -e "\e[31mDetected intel fortran binary\e[0m"
        MPIRUN="/opt/openmpi-1.10.0-intel/bin/mpirun --prefix /opt/openmpi-1.10.0-intel"
    else
        MPIRUN=mpirun
    fi
    echo "$MPIRUN -np $nMpiTasks ./$theBinary"
    $MPIRUN -np $nMpiTasks ./$theBinary
fi
    
## MPI return   
mpiReturn=$?
echo -e "\e[36mReturn code: $mpiReturn\e[0m"

## THis dosent work under qsub because stdout/err arent written untill after the job completes.
if [ ! -z $cleanRunDateId ]
then
    cd $origDir
    mv ${cleanRunDateId}.* ${runDir}/.
fi

exit $mpiReturn
