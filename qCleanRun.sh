#!/bin/bash

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`
cleanRunHelp=`$whsPath/cleanRun.sh | tail -n+2`

help="
qCleanRun :: help

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

IFS=$'\n'
nCores=$1
## fix this needs some rounding maths... apparently not trivial w bc
nNodes=`echo "$nCores/16" | bc`
#echo $nNodes
#echo "$allArgs"

workingDir=`pwd`

theDate=`date '+%Y-%m-%d_%H-%M-%S'`
jobFile=job.qCleanRun.$theDate

## fix: can I make the job name more informative? 

echo "#!/bin/bash
#PBS -l nodes=$nNodes:ppn=16,walltime=20:00:00
#PBS -k oe
#PBS -o stdout.$theDate.txt
#PBS -e stderr.$theDate.txt
#PBS -N wrfhydro

source ~/.bashrc

## To communicate where the stderr/out and job scripts are and their ID
export cleanRunDateId=${theDate}

cd $workingDir

$whsPath/cleanRun.sh ${allArgs}
modelReturn=\$?

unset cleanRunDateId

echo \"model return: \$modelReturn\"
exit $modelReturn" > $jobFile

qJobId=`qsub $jobFile`
echo $qJobId
## fix: want to put this into a file in the run directory... 
## but theres some complex parsing of the arguments to get that... it's in cleanRun.
#qJobId=`echo $qJobId | cut -d '.' -f 1`
#echo "$sJobId" > $runDir/qsubJobId.log

exit 0
