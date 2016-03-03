#!/bin/bash

help='
geyser.sh

At least one option must be specified. 

Options: 
-j job name.          default = myJob
-n # cores.           default = 8
-w wall time          default = 24:00
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
while getopts "::n:j:w:hd" opt; do
    case $opt in
        j) jobName="${OPTARG}" ;;
        n) nCores="${OPTARG}" ;;
        w) wallTime="${OPTARG}" ;;
        h) echo "$help"; exit 0 ;;
    esac 
done
shift "$((OPTIND-1))" # Shift off the option
echo "jobName:  $jobName"
echo "nCores:   $nCores"
echo "wallTime: $wallTime"

hrs=`echo $wallTime | cut -d':' -f1`
min=`echo $wallTime | cut -d':' -f2`
[ ${#wallTime} -eq 5 ] || exit 1
[ ${#hrs} -eq 2 ] || exit 1
[ ${#min} -eq 2 ] || exit 1
## formalize these failures with a message?

#echo bsub -Is -q geyser -W "$wallTime" -n "$nCores" -P P48500028 -J "$jobName" $SHELL
bsub -Is -q geyser -W "$wallTime" -n "$nCores" -P P48500028 -J "$jobName" $SHELL
exit $?
