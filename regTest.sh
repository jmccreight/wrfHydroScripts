#!/bin/bash

help='

regTest.sh :: regression tests for WRF-Hydro

Options:
q) Run the job under qsub and wait for the results.
b) NOT TESTED!!! Run the job under bsub and wait for the results... NOT TESTED!!! 

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

Number of cores used in a regression test is equal to the number of hydro_diag.* files in 
the VERIFICATION directory.

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
## # of last outputs to compare passed to testNLast.sh.
## # of processors to use instead of default
## set of tests to specify.
## set of ouput files to check/test on

cleanRunScript=cleanRun.sh
while getopts ":bq" opt; do
  case $opt in
    q)
      cleanRunScript=qCleanRun.sh
      ;;
    b)
      cleanRunScript=bCleanRun.sh
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

## First check for ~/.wrfHydroRegressionTests.txt
configFile=~/.wrfHydroRegressionTests.txt
checkExist $configFile "$help" || exit 1

## Argument 1
theBinary=$1
checkBinary $theBinary "$help" || exit 1
theBinary=`getAbsPath $theBinary`

## Argument 2: optional path to test dir
regTestMenu=`getMenu $configFile 'Regression Tests Menu'`
if [ -z $2 ]
then 
    ## if no test specified, let user choose between canned options in configFile
    echo -e "\e[7;44;97mPlease select a test case by number (0 to quit):\e[0m"
    echo  -e "\e[96m$regTestMenu\e[0m"
    testDir=''
    while [ -z $testDir ] 
    do
        read caseNum
        if [[ ! $caseNum =~ ^-?[0-9]+$ ]]; then continue; fi
        ## pull that case out of the config file
        testDir=`echo "$regTestMenu" | egrep "$caseNum.*:" | cut -d'=' -f2 | tr -d ' '`
    done 
else
    testDir=$2
    ## if an integer, use it to select a canned test case from configFile
    if [[ $testDir =~ ^-?[0-9]+$ ]]    
    then
        testDir=`echo "$regTestMenu" | egrep "$testDir.*:" | cut -d'=' -f2 | tr -d ' '`
        if [ -z $testDir ]
        then
            echo -e "\e[31mPassed test case number did not successfully select a test case.\e[0m"
            echo -e "\e[31mPlease review your test case configu filee and help below:.\e[0m"
            cat $configFile
            echo "$help"
            exit 1
        fi

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
    testRunDir=`find $testDir -name 'hydro.namelist' | grep -v VERIFICATION`
    nRunDir=`echo "$testRunDir" | wc -l`
    if [[ $nRunDir -gt 1 ]]
    then
        echo -e "\e[31mMore than one run directory detected. Run directory in regression tests is identified by a unique hydro.namelist in a directory below the regression test. Please fix.\e[0m"
        exit 1
    fi
        testRunDir=`dirname $testRunDir`
fi


## Where is the attempt at the test to be made?
theDate=`date '+%Y-%m-%d_%H:%M:%S'`
nCores=`ls $testRunDir/VERIFICATION/diag_hydro.* | wc -l`
attemptDir=`grep attemptDir $configFile | cut -d'=' -f2 | tr -d ' '`
attemptDir=$attemptDir/`basename $theBinary`.${nCores}cores.`basename $testDir`.$theDate

attemptRunDir=${attemptDir}/`basename $testRunDir`
if [[ "$testRunDir" == "$testDir" ]] 
then
    attemptRunDir=${attemptDir}/
fi

## Is this a nudging case?
linkFlags=''
nudgingTest=`ls $testRunDir/nudging* 2>/dev/null | wc -l`
if [[ $nudgingTest ]]; then linkFlags='n'; fi
if [ ! -z $linkFlags ]; then linkFlags="-${linkFlags}"; fi
## Other cases can be added similarly

echo
echo -e "\e[7;44;97mSetup\e[0m"
echo -e "The binary               : $theBinary"
echo -e "The test directory       : $testDir"
echo -e "The test run directory   : $testRunDir"
echo -e "The attempt directory    : $attemptDir"
echo -e "The attempt run directory: $attemptRunDir"
echo -e "linkFlags: $linkFlags"


## Test case linking
## These test are supposed to be stable, so only linking should be needed.
echo
echo -e "\e[7;44;97mLinking\e[0m"
linkTest=`echo $testRunDir | tr -d ' ' | cut -c$((${#testDir}+2))-`
if [[ -z $linkTest ]]; then linkTest="."; fi
$whsPath/linkToTestCase.sh $linkFlags $linkTest $testDir $attemptDir
if [ ! $? -eq 0 ] 
then
    echo -e "\e[31mLinking failed, please investigate.\e[0m"
    exit 1
fi

## link the binary
ln -s $theBinary $attemptRunDir/.
cd $attemptRunDir
ln -s `basename $theBinary` wrf_hydro.exe

## run the model
echo -e "\e[7;44;97mRun the model, using $nCores cores.\e[0m"
if [[ $cleanRunScript == cleanRun.sh ]]
then
    $whsPath/$cleanRunScript $nCores
    modelSuccess=$?
else
    if [[ $cleanRunScript == bCleanRun.sh ]]
    then
        # example: Job <300629> is submitted to queue <premium>.
        bJobId=`$whsPath/$cleanRunScript $nCores`
        bJobId=`echo $bJobId | cut -d '<' -f2 | cut -d'>' -f1`
        echo $bJobId -------
        monitorBsubJob $bJobId
        modelSuccess=$?
    else 
        ## else job was submitted to qsub
        qJobId=`$whsPath/$cleanRunScript $nCores`
        qJobId=`echo $qJobId | cut -d '.' -f 1`
        echo $qJobId
        modelSuccess=`monitorQsubJob $qJobId`
    fi
fi

if [[ ! $modelSuccess -eq 0 ]] 
then
    echo -e "\e[31mModel failed. Please investigate.\e[0m"
    exit $modelSuccess
fi

## compare the output
## what if OUPUT dir is specified by the namelist.hrldas?
echo -e "\e[7;44;97mOutput comparison:\e[0m"
$whsPath/testNLast.sh 1 $testRunDir/VERIFICATION 
retComp=$?

## fix do we want to link the VERIFICATION dir into the attempt director, ensuring it is write protected?

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
