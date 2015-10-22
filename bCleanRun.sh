#!/bin/bash

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`
cleanRunHelp=`$whsPath/cleanRun.sh | tail -n+2`

help="
bCleanRun :: help

Purpose: submit cleanRun calls to qsub automatically calculating the number of nodes
requested in the header from the number of cores/mpitasks askedfor and divided 
by 16. (Assumes the job is to be run from the current dir, where the binary is found.)

Other header items to qsub may need adjusted on an individual basis.

Arguments as for cleanRun...
$cleanRunHelp
"

if [ -z $1 ]
then
    echo -e "\e[31mPlease pass arguments to cleanRun.\e[0m $help"
    exit 1
fi

allArgs=$@
while getopts ":fpuncdor" opt; do
  case $opt in
    \?)
          echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift "$((OPTIND-1))" 

source $whsPath/helpers.sh

IFS=$'\n'
nCores=`echo $1 | bc`
nNodes=`ceiling $nCores/16`
#echo $nNodes
#echo $nCores
#echo "$allArgs"

workingDir=`pwd`

theDate=`date '+%Y-%m-%d_%H-%M-%S'`
jobFile=job.bCleanRun.$theDate

echo "#!/bin/bash
#BSUB -P P48500028                         # Project 99999999
#BSUB -x                                           # exclusive use of node (not_shared)
#BSUB -n $nCores                            # number of total (MPI) tasks
#BSUB -R \"span[ptile=16]\"             # run a max of  tasks per node
#BSUB -J  wh_nudging                       # job name
#BSUB -o stdout.$theDate.%J                          # output filename
#BSUB -estderr.$theDate.%J                           # error filename
#BSUB -W 12:00                                 # wallclock time (hrs:mins)
#BSUB -q premium                           # queue

source ~/.bashrc

## To communicate where the stderr/out and job scripts are and their ID
export cleanRunDateId=${theDate}

cd $workingDir

$whsPath/cleanRun.sh ${allArgs}
modelReturn=\$?

unset cleanRunDateId

echo \"model return: \$modelReturn\"
exit \$modelReturn" > $jobFile

bsub < $jobFile

exit 0