#!/bin/bash

IFS=$'\n'

out1='#!/bin/bash
#PBS -l nodes=1:ppn=16,walltime=20:00:00
#PBS -o logs/stdout.txt
#PBS -e logs/stderr.txt
#PBS -N wrfhydro

source ~/.bashrc
'

workingDir=`pwd`
out2="cd $workingDir
.$1 ${@:2}
exit 0"

echo "$out1"
echo "$out2"

exit 0
