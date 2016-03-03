#!/bin/bash

## Purpose: Automate WRF-Hydro restarts (binary files) under LSF (yellowstone). 
## Author: James McCreight 
## Notes:
## This script should handle
## 1) cold starts and subsequent restarts
## 2) restarts from clean exits
## 3) restarts from unclean exits (e.g. crahs, run-time limits, etc).
##
## This script can be run
## 1) Recursively, from within an LSF job.
##    This is THE PRIMARY WAY THIS HAS BEEN TESTED.
##    When the $exitScript variable is not null, 
##    a) This script creates a script which 
##    b) runs the model
##    c) calls this script (back to a).
##    The $noRestartAfter parameter/variable specifies a date past 
##    which restarts will not be performed. 
## 2) Via a cron job or other which checks if the LSF run has completed.
##    For this mode, set existScript=''


## The gist of how this works is the last CHRTOUT file time is taken as the 
## clock time before which restart files are successful (in case the model 
## was killed/crashed while writing restarts). If the latest restarts advance 
## in model time wrt the last restart requested (currently in the namelists), 
## then their dates are inserted into namelist.hrldas and hydro.namelist.


## A preliminary configuration section exists to clean up output files as 
## desired prior to restart.

##############################################################################
## EDIT THIS SECTION!!!
runDir=/glade/scratch/jamesmcc/CONUS/iocTests/run.cycle-lake-pstTrue
execName=wrf_hydro.333a570+.NWC_V1.HYDRO_REALTIME-WRFIO_NCD_LARGE_FILE_SUPPORT-HYDRO_D-WRF_HYDRO_NUDGING.exe
noRestartAfter=2016-01-01  ## the date after which to stop setting up restarts
wallTime=01:30
queue=premium
exitScript=restartLsfJob.sh  ## path/name of this file

outDir=$runDir/output      ## default/convention $runDir/output
jobName=cyLkPT             ## default to myJob or date +'%Y%m%d%H%M%S' ??
## EDIT THE ABOVE SECTION!!!
##############################################################################

#####################################
## setup
rstDir=$runDir/restart  ## not optional. but also not using...  since next line
cd $runDir

## setup the required directories inside the run directory if they dont exist.
if [ ! -e $rstDir ]; then mkdir $rstDir; fi
if [ ! -e $outDir ]; then mkdir $outDir; fi

## assuming binary restarts: get the # of processors used from the # restart files.
nCores0=`ls restart/RESTART.* | head -1 | cut -d'.' -f1-2`
nCores=`ls ${nCores0}.* | wc -l`

## If there are no restart files, make sure the namelists are NOT trying to restart.
if [ $nCores -eq 0 ]; then
    hydroRstCommented=`cat hydro.namelist | tr -d ' ' | egrep '^RESTART_FILE' | wc -l`
    restartCommented=`cat namelist.hrldas | tr -d ' ' | egrep '^RESTART_FILENAME' | wc -l`
    if [ $restartCommented -ne 0 ] || [ $hydroRstCommented -ne 0 ]; then
        echo 'There are no restart files to start from as requested in a namelist.'
        exit 1
    fi
fi

## Clean up the run to the $outDir, this safe guards output files but leaves restarts in the
## restart/ directory
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` || exit 1
source $whsPath/sourceMe.sh
cleanup $outDir  || exit 1


#####################################
## do we really want to restart?
## since there's no way to really detect if the model crashed and thereby 
## control calls to this script, we'll exit now if
## 1) the restart times in the namelists match the last available restarts
## 2) a specified time is exceeded by the last available restarts
noRestartAfterSec=`date -u -d $noRestartAfter +%s`
prevRestart=`grep -e '\s*RESTART_FILENAME_RE.*' namelist.hrldas | tr -d ' "' | cut -d'=' -f2`
prevRestartY=`basename $prevRestart | cut -c9-12`
prevRestartM=`basename $prevRestart | cut -c13-14`
prevRestartD=`basename $prevRestart | cut -c15-16`
prevRestartH=`basename $prevRestart | cut -c17-18`
prevRestartSec=`date -d "$prevRestartY-$prevRestartM-$prevRestartD $prevRestartH" +%s`

#####################################
## what was the last restart written to disk?
## in figuring out the restart a primary concern is that the model run ended while 
## writing restarts. Dont want to restart with garbage files.
## So compare the file times of last restart file to the last CHRTOUT file
## HYDRO_RST is written before CHRTOUT_DOM which is written before RESTART. 
## based on last CHRTOUT_DOM, find the earlier HYDRO_RST. This should imply RESTART 
## since the CHRTOUT_DOM exists.

## get file time last CHRTOUT
## *** all VALID restarts were written before the last CHRTOUT ***
lastChrtLs=`ls -1rt $outDir/*CHRTOUT_DOM* | tail -1` || exit 1

## get date of last RESTART which is BEFORE the last CHRTOUT_DOM
lastRestartFile=`find restart/HYDRO_RST* ! -newer $lastChrtLs -printf "%T+ %p\n" | sort | tail -1 | cut -d' ' -f2` || exit 1

restartY=`basename $lastRestartFile | cut -c11-14`
restartM=`basename $lastRestartFile | cut -c16-17`
restartD=`basename $lastRestartFile | cut -c19-20`
restartH=`basename $lastRestartFile | cut -c22-23`
restartSec=`date -d "$restartY-$restartM-$restartD $restartH" +%s`

#####################################
## is the last restart written to disk
## 1) the same as (or earlier than) the previously specified restart in the namelist?
## 2) greater than specified limit?
if [ $restartSec -le $prevRestartSec ] || [ $restartSec -gt $noRestartAfterSec ]
then
    echo "Last restart is either same as or earlier than previous restart OR"
    echo "is greater than the specified last date requested. No more restarts... exiting."
    exit 1
fi

#####################################
## double check that we have all LDAS and HYDRO restart files.
## this really should not happen -- but best to at least test for it.
## make sure there are 512 RESTART files with this time, all OLDER than the 
## latest CHRTOUT
nRestarts=`ls restart/RESTART.${restartY}${restartM}${restartD}${restartH}* | wc -l` || exit 1
nHydroRsts=`ls restart/HYDRO_RST.${restartY}-${restartM}-${restartD}_${restartH}* | wc -l` || exit 1
## make sure we have 512 of both (all of which are older than last CHRTOUT
if [ ! $nRestarts -eq $nCores ] || [ ! $nHydroRsts -eq $nCores ]
then
    echo 'unforseen issue with setting up new restart, please investigate'
    exit 1
fi

#####################################
## edit the namelist files to pickup the new restarts
sed -i "s/\s*START_YEAR.*/ START_YEAR = $restartY/" namelist.hrldas    || exit 1
sed -i "s/\s*START_MONTH.*/ START_MONTH = $restartM/" namelist.hrldas  || exit 1
sed -i "s/\s*START_DAY.*/ START_DAY = $restartD/" namelist.hrldas      || exit 1
sed -i "s/\s*START_HOUR.*/ START_HOUR = $restartH/" namelist.hrldas    || exit 1

## what if the restart line(s) are commented?
hydroRstCommented=`cat hydro.namelist | tr -d ' ' | egrep '^RESTART_FILE' | wc -l`
if [ $hydroRstCommented -eq 0 ]; then 
    sed -i '0,/.*!.*RESTART_FILE/s/.*!.*RESTART_FILE/ RESTART_FILE/' hydro.namelist
fi

restartCommented=`cat namelist.hrldas | tr -d ' ' | egrep '^RESTART_FILENAME' | wc -l`
if [ $restartCommented -eq 0 ]; then 
    sed -i '0,/.*!.*RESTART_FILENAME/s/.*!.*RESTART_FILENAME/ RESTART_FILENAME/' namelist.hrldas
fi

sed -i "s/\s*RESTART_FILENAME_RE.*/ RESTART_FILENAME_REQUESTED = \"restart\/RESTART.${restartY}${restartM}${restartD}${restartH}_DOMAIN1\"/" namelist.hrldas           || exit 1

sed -i "s/\s*RESTART_FILE.*/ RESTART_FILE = \"restart\/HYDRO_RST.${restartY}-${restartM}-${restartD}_${restartH}:00_DOMAIN1\"/" hydro.namelist                         || exit 1

egrep '(START_YEAR|START_MONTH|START_DAY|START_HOUR|RESTART_FILENAME_RE)' namelist.hrldas
egrep 'RESTART_FILE' hydro.namelist

#####################################
## submit the job, of course calling this script!
$whsPath/bCleanRun.sh -n -j $jobName -W $wallTime -q $queue -e $exitScript $nCores $execName  || exit 1

exit 0