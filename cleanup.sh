#!/bin/bash

## Purpose: Clean up a WRF-Hydro run/ouyput. 
## Options
## -r : Remove all restarts. 
## Arguments:
## 1) A directory into which the clean up is done. 

removeRestarts=1  ## do not remove restarts by default, unless -r flag.
while getopts ":r" opt; do
  case $opt in
    r)
      echo "Removing restarts"
      removeRestarts=0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

if [ ! -z "$1" ]
then

    if [ -d "$1" ]; then
        mv -f *.CHANOBS_DOMAIN*    $1/.
        mv -f *.CHRTOUT_DOMAIN*    $1/.
        mv -f *.CHRTOUT_GRID*      $1/.
        mv -f *.LAKEOUT_DOMAIN*    $1/.
        mv -f *.LSMOUT_DOMAIN*     $1/.
        mv -f *.RTOUT_DOMAIN*      $1/.
        mv -f HYDRO_RST.*_DOMAIN*  $1/.
        mv -f RESTART.*_DOMAIN*    $1/.
        mv -f frxst_pts_out.txt    $1/.
        mv -f qstrmvolrt_accum.txt $1/.
        mv -f *.LDASOUT_DOMAIN*    $1/.
        mv -f diag_hydro.*         $1/.
        mv -f GW_*.txt             $1/.
        mv -f NWIS_gages_not_in_RLAndParams.txt $1/.
        mv -f nudgingLastObs.*.nc  $1/.
#        mv -f 
    else 
        echo "No such directory: " $1
        echo "Aborting"
        exit 1
    fi
    
else 

    rm -f *.CHANOBS_DOMAIN*
    rm -f *.CHRTOUT_DOMAIN*
    rm -f *.CHRTOUT_GRID*
    rm -f *.LAKEOUT_DOMAIN*
    rm -f *.LSMOUT_DOMAIN*
    rm -f *.RTOUT_DOMAIN*
    ## I will NOT force remove restarts in case they were purposely write protected.
    if [[ $removeRestarts -eq 0 ]]; then rm HYDRO_RST.*_DOMAIN*; fi
    if [[ $removeRestarts -eq 0 ]]; then rm RESTART.*_DOMAIN*; fi
    if [[ $removeRestarts -eq 0 ]]; then rm nudgingLastObs.*.nc; fi
    rm -f frxst_pts_out.txt
    rm -f volrt_accum.txt
    rm -f *.LDASOUT_DOMAIN*
    rm -f diag_hydro.*
    rm -f GW_*.txt
    rm -f NWIS_gages_not_in_RLAndParams.txt

fi

exit 0
