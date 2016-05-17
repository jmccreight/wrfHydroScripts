#!/bin/bash

## Purpose: a script for cronjob reports of scratch file ages
## https://www2.cisl.ucar.edu/resources/storage-and-file-systems/glade-file-spaces#scratchspace
## check for files older than $1

me=`whoami`
echo $me

rm /glade/scratch/${me}/scratchDates.txt
/glade/u/home/jamesmcc/wrfHydroScripts/getScratchDates.Rsh $1 || exit 2
ls /glade/scratch/${me}/scratchDates.txt

if [ $? -eq 0 ]; then
    message1="*** Only showing files older than 40 days in this email.       ***"
    message2="*** See /glade/scratch/${me}/scratchDates.txt for full report. ***"
    message3=`egrep '^(#|[4-9])' /glade/scratch/${me}/scratchDates.txt`
    message=`echo -e "$message1"\\\n"$message2"\\\n"$message3"`
else 
    message=Failed to generate /glade/scratch/${me}/scratchDates.txt
fi

echo -e "$message" | mail -s "Age report for /glade/scratch/${me}" ${me}@ucar.edu 

exit 0
