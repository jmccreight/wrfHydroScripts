#!/bin/bash

help='
geyser.sh

At least one option must be specified. 

Options: 
-j job name.          default = myJob
-n # cores.           default = 8
-W wall time          default = 24:00
-q queue              default = geyser
-d Run with defaults.
-h This help message.
'

if [ -z $@ ]; then
    echo "$help"
    exit 0
fi

jobName=myJob
nCores=8
wallTime=24:00
queue=geyser
while getopts "::n:j:W:q:hd" opt; do
    case $opt in
        j) jobName="${OPTARG}" ;;
        n) nCores="${OPTARG}" ;;
        W) wallTime="${OPTARG}" ;;
        q) queue="${OPTARG}" ;;
        h) echo "$help"; exit 0 ;;
    esac 
done
shift "$((OPTIND-1))" # Shift off the option

project=`egrep '^#BSUB -P' ~/.wrfHydroScripts`
nProject=`echo "$project" | wc -l`
if [[ $nProject -ne 1 ]]; then
    if [[ $nProject -eq 0 ]]; then echo "Error: no project specified in ~/.wrfHydroScripts"; fi
    if [[ $nProject -gt 1 ]]; then echo "Error: multiple projects specified in ~/.wrfHydroScripts"; fi
    exit 1
fi
project=`echo $project | cut -d' ' -f3`

echo "queue:    $queue"
echo "jobName:  $jobName"
echo "nCores:   $nCores"
echo "wallTime: $wallTime"
echo "project:  $project"

hrs=`echo $wallTime | cut -d':' -f1`
min=`echo $wallTime | cut -d':' -f2`
[ ${#wallTime} -eq 5 ] || exit 1
[ ${#hrs} -eq 2 ] || exit 1
[ ${#min} -eq 2 ] || exit 1
## formalize these failures with a message?

#echo bsub -Is -q geyser -W "$wallTime" -n "$nCores" -P P48500028 -J "$jobName" $SHELL
bsub -Is -q "$queue" -W "$wallTime" -n "$nCores" -P "$project" -J "$jobName" $SHELL
exit $?
