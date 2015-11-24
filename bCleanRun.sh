#!/bin/bash

## fix: check for .wrfHydroScripts?

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`
cleanRunHelp=`$whsPath/cleanRun.sh | tail -n+2`

help="
bCleanRun :: help

Purpose: submit cleanRun calls to bsub automatically 
Header items to qsub may need adjusted on an individual basis in this script.
(Assumes the job is to be run from the current dir, where the binary is found.)

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
jobFile=$theDate.bCleanRun.job

bsubHeader=`egrep '^#BSUB' ~/.wrfHydroScripts`
bsubHeader=`echo "$(eval "echo \"$bsubHeader\"")"`

echo "#!/bin/bash
$bsubHeader

#source ~/.bashrc
source $whsPath/helpers.sh

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
