#!/bin/bash

help='
perfectRestartCoreTest.sh :: restart tests on a group of model runs 

Premise: Three runs:
1) long N, a cold start run using N cores 
2) short N, a restart from 1 also using N cores
3) short M, a restart from 1 but using M cores (generally N-1)

Arguments:
1) prefix pattern speficying the group of model runs 
2) the number of cores N
3) optional: the number of cores M, defaults to N-1

TODO: some sort of path specificiation

'

if [ -z $1 ] || [ -z $2 ]
then
    echo "$help"
    exit 1
fi

pattern=$1
nCores=$2
if [ -z $3 ]; then mCores=$(($nCores-1)); else mCores=$3; fi

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

ncosPath=`grep "ncoScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $ncosPath/ncFilters.sh

## First check for ~/.wrfHydroRegressionTests.txt
configFile=~/.wrfHydroRegressionTests.txt
checkExist $configFile || exit 1

## eventually, these tests will be in the attempt dir
#attemptDir=`grep attemptDir $configFile | cut -d'=' -f2 | tr -d ' '`
#cd $attemptDir
cd /home/jamesmcc/WRF_Hydro/TESTING/TESTS

## check that exactly 3 directories match
matches=`ls -1d *${pattern}*`
nMatches=`echo "$matches" | wc -l`

if [ ! $nMatches -eq 3 ]
then
    echo -e "More or less than 3 directories match the supplied pattern, exiting."
    ls -1d *${pattern}*
    echo "$help"
    exit 1
fi

long=`echo "$matches" | grep -i long`
shortN=`echo "$matches" | grep -i _short_ | grep ${nCores}Cores`
shortM=`echo "$matches" | grep -i _short_ | grep ${mCores}Cores`

## restart tests 
## what is the last RESTART in LONG?
lastRestart=`ls -1 $long/VERIFICATION/RESTART* | tail -1`
lastRestart=`basename $lastRestart`

## what is last HYDRO_RST in LONG?
lastHydroRst=`ls -1 $long/VERIFICATION/HYDRO_RST* | tail -1`
lastHydroRst=`basename $lastHydroRst`

accumReturns=0
## RESTART
echo
echo -e "\e[7;47;39mTesting LONG and SHORT restarts with same number of cores:\e[0m"
echo "ncVarDiff $long/VERIFICATION/${lastRestart} 
          $shortN/VERIFICATION/${lastRestart}"
ncVarDiff $long/VERIFICATION/${lastRestart} \
          $shortN/VERIFICATION/${lastRestart}
accumReturns=$(($accumReturns+$?))

## HYDRO_RST
echo
echo "ncVarDiff $long/VERIFICATION/${lastHydroRst} 
          $shortN/VERIFICATION/${lastHydroRst}"
ncVarDiff $long/VERIFICATION/${lastHydroRst} \
          $shortN/VERIFICATION/${lastHydroRst}
accumReturns=$(($accumReturns+$?))

echo
echo -e "\e[7;47;39mDifferent # core restart tests:\e[0m"
## RESTART
echo "ncVarDiff $shortN/VERIFICATION/${lastRestart} 
          $shortM/VERIFICATION/${lastRestart}"
ncVarDiff $shortN/VERIFICATION/${lastRestart} \
          $shortM/VERIFICATION/${lastRestart}
accumReturns=$(($accumReturns+$?))

## HYDRO_RST
echo
echo "ncVarDiff $shortN/VERIFICATION/${lastHydroRst} 
          $shortM/VERIFICATION/${lastHydroRst}"
ncVarDiff $shortN/VERIFICATION/${lastHydroRst} \
          $shortM/VERIFICATION/${lastHydroRst}
accumReturns=$(($accumReturns+$?))

echo
echo -e "\e[31mAccumulated errors: $accumReturns\e[0m"

exit $accumReturns
