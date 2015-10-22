#!/bin/bash
## Purpose: put a qsub header on another script, pass all the arguments, and submit to qsub.

## Arguments 
## 1) the path/script.sh name to the script you want to run in qsub/torque.
## 2+) Arguments to the script in 1.

IFS=$'\n'

nCores=$2
nNodes=`echo "$nCores/16" | bc`
workingDir=`pwd`
theDate=`date '+%Y-%m-%d_%H:%M:%S'`
jobFile=job.qCleanRun.$theDate

echo "#!/bin/bash
#PBS -l nodes=$nNodes:ppn=16,walltime=20:00:00
#PBS -o logs/stdout.txt
#PBS -e logs/stderr.txt
#PBS -N wrfhydro

source ~/.bashrc

cd $workingDir
$1 -n ${@:2}

rm $jobFile
exit 0" > $jobFile

qsub $jobFile


exit 0
