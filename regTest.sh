#!/bin/bash

help='

regTest.sh :: regression tests for WRF-Hydro

Arguments:
1) The binary to test
2) [optional] The regression test case as a path/directory or 
   an integer to refererence existing test cases stored in 
   ~.wrfHydroRegressionTests.`hostname`.txt. If missing,
   the list in this file is printed for interactive selection.


Regression tests are directories that have all the necessary components for a model run. They 
may contain the actual model run directory as a subdirectory (some times necessary to facilitate 
linking/copying as established in the namelists). The regression test run directory is found 
by searching for "hydro.namelist" in its contents.

The regression test directories also contaion a special VERIFICATION directory *IN THE RUN
DIRECTORY*. The binary and all the model ouput are located in VERIFICATION/. Old version can 
be back-dated, e.g. VERIFICATION.yyyymmdd or removed.

Number of cores used is equal to the number of hydro_diag.* files in the VERIFICATION 
directory.

Running a regression test: involves the following steps
0) Creation of an enclosing directory named after the regression test, the binary, and the date.
1) Symlinks/copies this regression test into the above directory,
2) Copies your binary there,
3) Runs the test,
4) Compares the output to VERIFICATION in the run directory,
5) optionally cleans up on success.

Maybe some day well have autmoatic/continuous integrations:
https://github.com/integrations/feature/build
'
##future arguments
## # of last outputs to compare passed to compareOutputs.

## First check for ~/.wrfHydroRegressionTests.txt
configFile=~/.wrfHydroRegressionTests.txt
if [ ! -e $configGile ] 
then 
    echo -e "\e[31mYour ~/.wrfHydroRegressionTests.txt does not exist.\e[0m $help"
    exit 1
fi

## Argument 1
theBinary=$1
if [ -z $theBinary ]; then echo -e "\e[31mNo binary supplied, returning.\e[0m $help"; exit 1; fi
if [ ! -e $theBinary ] 
then
    echo -e "\e[31mBinary does not exist: $theBinary\e[0m $help"
    exit 1
fi
checkBinary=`ldd $theBinary`
if [ ! $? -eq 0 ] 
then
    echo -e "\e[31mProblems with executable:\e[0m wrf_hydro.exe"
    exit 1
fi

if [[ `dirname $theBinary` == '.' ]];then theBinary=`pwd`/$theBinary; fi

## Argument 2: optional path to test dir
if [ -z $2 ]
then 
    ## if no test specified, let user choose between canned options in configFile
    echo -e "\e[7;44;97mPlease select a test case by number (0 to quit):\e[0m"
    echo -e "\e[96m `egrep '[1-9]*:' $configFile` \e[0m"
    read caseNum
    echo $caseNum
    ## pull that case out of the config file
    testDir=`egrep "$caseNum.*:" $configFile | cut -d'=' -f2 | tr -d ' '`
else
    testDir=$2
    ## if an integer, use it to select a canned test case from configFile
    if [[ $testDir =~ ^-?[0-9]+$ ]]    
    then
        testDir=`egrep "$testDir.*:" $configFile | cut -d'=' -f2 | tr -d ' '`
    fi
fi

## Check existence of test directory 
if [ -z $testDir ]; then 
    echo -e "\e[31mNo such test case or directory: $testDir\e[0m $help"
    exit 1
fi
if [ ! -d $testDir ]
then
    echo -e "\e[31mThe test directory does not exist: $testDir\e[0m $help"
    exit 1
else 
    ## if it exists find the first hydro.namelist as the actual run directory
    testRunDir=`find $testDir -name 'hydro.namelist'`
    testRunDir=`dirname $testRunDir`
fi

## Where is the attempt at the test to be made?
theDate=`date '+%Y-%m-%d_%H:%M:%S'`
nCores=`ls $testRunDir/VERIFICATION/diag_hydro.* | wc -l`
attemptDir=`grep attemptDir $configFile | cut -d'=' -f2 | tr -d ' '`
attemptDir=$attemptDir/`basename $theBinary`.${nCores}cores.$theDate.`basename $testDir`
attemptRunDir=${attemptDir}/`basename $testRunDir`

echo
echo -e "\e[7;44;97mSetup\e[0m"
echo -e "The binary               : $theBinary"
echo -e "The test directory       : $testDir"
echo -e "The test run directory   : $testRunDir"
echo -e "The attempt directory    : $attemptDir"
echo -e "The attempt run directory: $attemptRunDir"

## Test case linking
## These test are supposed to be stable, so only linking should be needed.
echo
echo -e "\e[7;44;97mLinking\e[0m"
linkTest=`echo $testRunDir | tr -d ' ' | cut -c$((${#testDir}+2))-`
~jamesmcc/wrfHydroScripts/linkToTestCase.sh $linkTest $testDir $attemptDir
## link the binary
ln -s $theBinary $attemptRunDir/.
cd $attemptRunDir
ln -s `basename $theBinary` wrf_hydro.exe

## run the model
echo
echo -e "\e[7;44;97mRun the model, using $nCores cores.\e[0m"
~jamesmcc/wrfHydroScripts/cleanRun.sh $nCores
modelSuccess=$?
if [[ ! $modelSuccess -eq 0 ]] 
then
    echo -e "\e[31mModel failed. Please investigate.\e[0m"
    exit $modelSuccess
fi

## compare the output
## what if OUPUT dir is specified by the namelist.hrldas?
echo -e "\e[7;44;97mOutput comparison:\e[0m"
~jamesmcc/wrfHydroScripts/compareOutputs.sh 1 $testRunDir/VERIFICATION 
retComp=$?

echo -e "\e[7;44;97mOutput comparison results:\e[0m"
if [ $retComp -eq 0 ]
then
    echo -e "\e[31mResults matched perfectly! You may remove the test attempt directory: rm -rf $attemptDir\e[0m"
    ##cd ~
    ## this makes me nervous... what if the attempt dir were accidentally ~?
    #rm -rf $attemptDir
else
    echo -e "\e[31mResults did not match perfectly. The test attempt directory: $attemptDir\e[0m"
fi
echo

## compare+ report run times
echo -e "\e[7;44;97mTiming results:\e[0m"
timeGrepStr="accumulated time (s):"
echo -e "\e[31mVerification time: \e[0m"`grep "$timeGrepStr" $testRunDir/VERIFICATION/diag_hydro.00000 | tail -1`
echo -e "\e[31mYour binary time:  \e[0m"`grep "$timeGrepStr" diag_hydro.00000 | tail -1`

exit 0