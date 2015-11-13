#!/bin/bash
##

help='
updateTests.sh :: update selected (via regex) with supplied binary

Arguments:
1) pattern matched in test dir via egrep regex to determine directories to update
2) is binary to use for the update

For all directories matching pattern in TESTS 
    1) ask user if matching directories are the desired directories.
    2) in each directory:
       2.a) diff old and new binaries 
       2.b) if binaries same:      only run tests if VERIFICATION/ does NOT exist
            if binaries different: run test

'

if [ -z $1 ] 
then
    echo "$help"
    exit 1
fi

pattern=$1 #FRNG_MASTER_15Min
theBinary=$2 #/home/jamesmcc/WRF_Hydro/wrf_hydro_model/trunk/NDHMS/Run/wrf_hydro.master.9a4bbd1.exe

## helpers
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

## get full path to binary and make sure it exists
theBinary=`getAbsPath $theBinary`
checkBinary $theBinary "$help" || exit 1


## Another way to detect the test dir?
cd /d6/jamesmcc/WRF_Hydro/TESTING/TESTS

## check that the matches to pattern are OK
matches=`ls -1d * | egrep $pattern`
echo "$matches"

echo 'Do you wish to replace the binary in all of the above test cases and rerun the tests, y/n?'
read keepGoing

if [ ! `echo $keepGoing | cut -c1` == 'y' ]
then 
    echo "You did not answer 'y', exiting."
    exit 1
fi

for tt in $matches
do
    echo --------
    echo $tt
    cd $tt
    ## diff the binary before doing the test
    ## print a warning and skip the test   
    diff wrf_hydro*exe $theBinary
    if [ $? -eq 0 ] && [ -d VERIFICATION ] 
    then
        echo -e 'Binary files are identical and VERIFICATION/ exists, skipping this test.'
        cd ..
        continue 
    fi

    rm wrf_hydro*exe
    cp $theBinary .
    ./runScript.sh `basename $theBinary`
    cd ..
done

exit 0
