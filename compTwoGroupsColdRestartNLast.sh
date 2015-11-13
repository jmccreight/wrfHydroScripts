#!/bin/bash


help='
compTwoGroupsColdRestartNLast.sh :: Test equality of cold and restart outputs for different binaries.

Premise: Two groups each with three runs:
1) long N, a cold start run using N cores 
2) short N, a restart from 1 also using N cores
3) short M, a restart from 1 but using M cores (generally N-1)
Ignore 3. Test equivalance between the two groups of 1 and 2.

Arguments:
1) prefix pattern speficying group 1
2) prefix pattern speficying group 2

TODO: check nFIRST
TODO: pass number of files in nLast/nFirst

TODO: what if the runs are of unequal length? 
TODO: i think that testNLast first argument is the one which "tail" is performed.
TODO: that would be the corresponding arguemnt, the one with the shorter overlapping run

TODO: some sort of path specificiation

'

if [ -z $1 ] || [ -z $2 ]
then
    echo "$help"
    exit 1
fi

pattern1=$1
pattern2=$2

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh
source $whsPath/sourceMe.sh

ncosPath=`grep "ncoScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $ncosPath/ncFilters.sh

## First check for ~/.wrfHydroRegressionTests.txt
#configFile=~/.wrfHydroRegressionTests.txt
#checkExist $configFile "$help" || exit 1
#attemptDir=`grep attemptDir $configFile | cut -d'=' -f2 | tr -d ' '`
## how i name the attempt in regTests
# attemptDir=$attemptDir/`basename $theBinary`.${nCores}cores.$theDate.`basename $testDir`
## setup test dir here. 
## right now not really doing this as I will once 
## base tests exist... 
cd /home/jamesmcc/WRF_Hydro/TESTING/TESTS


matches1=`ls -1d *${pattern1}*`
nMatches1=`echo "$matches1" | wc -l`
long1=`echo "$matches1" | grep -i long`
short1=`echo "$matches1" | grep -i _short_ | tail -1`

matches2=`ls -1d *${pattern2}*`
nMatches2=`echo "$matches2" | wc -l`
long2=`echo "$matches2" | grep -i long`
short2=`echo "$matches2" | grep -i _short_ | tail -1`


accumReturns=0
## Cold start
echo
echo -e "\e[7;47;39mComparing cold start runs final files:\e[0m"
echo -e "testNLast 1 $long1/VERIFICATION/ \
            $long2/VERIFICATION/"
testNLast 1 $long1/VERIFICATION/ \
            $long2/VERIFICATION/
accumReturns=$(($accumReturns+$?))

echo
echo -e "\e[31mAccumulated errors at this point: $accumReturns\e[0m"

## REstart
echo
echo -e "\e[7;47;39mComparing REstart runs final files:\e[0m"
echo -e "testNLast 1 $short1/VERIFICATION/ \
            $short2/VERIFICATION/"
testNLast 1 $short1/VERIFICATION/ \
            $short2/VERIFICATION/
accumReturns=$(($accumReturns+$?))

echo
echo -e "\e[31mAccumulated errors: $accumReturns\e[0m"

exit $accumReturns
