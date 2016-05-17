#!/bin/bash

## Set default options
wallTime=11:44
queue=geyser
projectCode=NRAL0008

help="
r2Geyser :: help
Purpose: Submit R scripts (which parse commandArgs, see below) to geyser queue.

Options: (defaults set inside script NOT in ~/.wrfHydroScripts)
J) jobName: unique job identifer,  must not already be in queue.
W) wallTime: HH:MM <= 24:00, default=$wallTime
q) queue: geyser(nCores<=16) or bigmem(nCores=40), default=$queue
P) projectCode: project code, default=$projectCode

Arguments:
1) REQUIRED path/name of R script to invoke. 
2) REQUIRED number of cores to use for job (typically 16).
3+) Optional arguments to be passed to R script.

R-script arguments:
The requirement is that the first argument to the R script is the number of cores it will
use. This is to match the number of cores requested on geyser.
The remaining arguments are arbitrary, for now they are positional. The required code:
args <- commandArgs(TRUE)
nCores <- as.integer(args[1])
...
someVarN <- as.numeric(args[N])  ##for example
...
"

while getopts ":J:P:W:q:" opt; do
    case $opt in
        J) jobName="${OPTARG}" ;;
        W) wallTime="${OPTARG}" ;;
        q) queue="${OPTARG}" ;;
        P) projectCode="${OPTARG}" ;;
        \?) echo -e "\e[31mInvalid option: -$OPTARG \e[0m $help"
            exit 1
    esac 
done
shift "$((OPTIND-1))" # Shift off the option

if [ -z $1 ];then
    echo -e "\e[31mTwo arguments are required by r2Geyser.sh. You passed only ${#@}.\e[0m $help"
    exit 1
fi

## take the remaining args
rScript=$1
shift
nCores=$1
shift
leftArgs=$@

## The R script must exist
if [ ! -e $rScript ]; then
    echo -e "\e[31mThe specified R script does not exist. Exiting.\e[0m $help"
    exit 1
fi

## Warn about core counts
if [[ $nCores -gt 40 || ( $nCores -ne 40 && $queue == bigmem ) || ( $nCores -gt 16 && $queue != bigmem) ]]; then
    echo -e "\e[31mThe specified # of cores=${nCores} does not make sense with queue=${queue}\e[0m $help"
    exit 1
fi

## Enforce use of job name
if [ -z $jobName ]; then
    echo -e "\e[31mThe -j option must be used to speficy a unique jobname.\e[0m $help"
    exit 1
fi

## Enforce that this job name is not already in the queue
myBjobNames=`bjobs -l | grep '^Job' | cut -d'<' -f3 | cut -d'>' -f1`
for jj in $myBjobNames; do
    if [ $jobName == $jj ]; then
        echo -e "\e[31mThe jobName: \"${jobName}\" is already in the queue and must be unique.\e[0m"
        echo "$help"
        exit 1
    fi
done

## Confirm options
echo nCores   = $nCores
echo jobName  = $jobName
echo wallTime = $wallTime
echo queue    = $queue

exe="Rscript --no-restore --no-save $rScript $nCores $leftArgs"
#echo "bsub -Is -q $queue -W $wallTime -n $nCores -P $projectCode -J $jobName $exe ; bkill -J $jobName"
bsub -Is -q $queue -W $wallTime -n $nCores -P $projectCode -J $jobName $exe ; bkill -J $jobName
exit 0