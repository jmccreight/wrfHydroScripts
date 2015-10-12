#!/bin/bash


help="
qCleanRun :: help

Purpose: submit cleanRun calls to qsub automatically calculating the number of nodes
requested in the header from the number of cores/mpitasks askedfor and divided 
by 16. (Assumes the job is to be run from the current dir, where the binary is found.)

Other header items to qsub may need adjusted on an individual basis.

"

if [ -z $1 ]
then
    echo -e "\e[31mPlease pass arguments to cleanRun.\e[0m $help"
    exit 1
fi

allArgs=$@
while getopts ":ucnp" opt; do
  case $opt in
    \?)
      ;;
  esac
done
shift "$((OPTIND-1))" 
IFS=$'\n'
nCores=$1
nNodes=`echo "$nCores/16" | bc`
#echo $nNodes
#echo "$allArgs"

workingDir=`pwd`
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`

theDate=`date '+%Y-%m-%d_%H-%M-%S'`
jobFile=job.qCleanRun.$theDate

echo "#!/bin/bash
#PBS -l nodes=$nNodes:ppn=16,walltime=20:00:00
#PBS -k oe
#PBS -o logs/stdout.$theDate.txt
#PBS -e logs/stderr.$theDate.txt
#PBS -N wrfhydro

source ~/.bashrc

cd $workingDir
$whsPath/cleanRun.sh ${allArgs}
modelReturn=$?
rm $jobFile
exit $modelReturn" > $jobFile

qsub $jobFile

exit 0




