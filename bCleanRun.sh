#!/bin/bash

## fix: check for .wrfHydroScripts?

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`
cleanRunHelp=`$whsPath/cleanRun.sh | tail -n+2`
source $whsPath/helpers.sh

help="
bCleanRun :: help

Purpose: submit cleanRun calls to bsub automatically 

Arguments: those for cleanRun - see below.
Options: 
-j jobName - used in forming the bsubHeader. (must come before args)
-W wallTime
-q queue
-e path/exitScript - a script to be invoked prior to successful exit.
Details:
Assumes the jobs run dir is the current dir, where the binary is found.
Header items to qsub may need adjusted on an individual basis in ~/.wrfHydroScripts
number of cores and job name are set via arguments to this script.

******
Arguments as for cleanRun...
$cleanRunHelp
"

if [ -z $1 ]
then
    echo -e "\e[31mPlease pass arguments to cleanRun.\e[0m $help"
    exit 1
fi

while getopts "::fpuncdorj:e:W:q:" opt; do
    case $opt in
        j) jobName="${OPTARG}" ;;
        W) wallTime="${OPTARG}" ;;
        q) queue="${OPTARG}" ;;
        e) exitScript="${OPTARG}" ;;
    esac 
done
shift "$((OPTIND-1))" # Shift off the option

allArgs=$@
IFS=$'\n'
nCores=`echo "${@:1:1}" | bc`
nNodes=`ceiling $nCores/16`
#echo "$allArgs"
if [ -z $jobName ]; then jobName=myRun; fi
if [ -z $wallTime ]; then wallTime=11:44; fi
if [ -z $queue ]; then queue=regular; fi
echo nCores   = $nCores
echo jobName  = $jobName
echo wallTime = $wallTime
echo queue    = $queue

if [ ! -z $exitScript ]
then
    exitScript="./${exitScript}"
    echo Exit script: "$exitScript"
fi


## check valid options
while getopts "::fpuncdor" opt; do
    case $opt in
        \?) echo "Invalid option: -$OPTARG"
            exit 1 ;;
    esac 
done
shift "$((OPTIND-1))" # Shift off the option


workingDir=`pwd`

## do it in local time. necessary for envs which dont source my bashrc
export TZ=America/Denver  
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

$exitScript

exit \$modelReturn" > $jobFile

bsub < $jobFile

exit 0
