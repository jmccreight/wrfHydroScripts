#!/bin/bash

help='

linkToTestCase.sh :: help

Purpose: to "duplicate" via symlinks someone elses (you dont have 
permission in their run dir) WRF-Hydro test case. You want all their 
dependencies as specified in their namelists (and really nothing more)
and all the run dependencies (namelists and *TBL files).

Arguments:
 1) ($test) The name of the test you want to link to relative to $rootDir, could be 
     several directories deep, e.g. testFOO/fooBAR
 2) The test directory, $testDir, where the source test lives, 
     e.g. /home/someTester/TESTS then the tests from 1 would be
     /home/someTester/TESTS/testFOO/fooBAR
 3) "myTestDir"  the directory into which the test is to be "copied",
     e.g. /home/myself/TESTS/specialTest the above examples would result in
     /home/myself/TESTS/specialTest/testFOO/fooBAR
'

if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ]; then echo -e "Argument(s) missing. $help"; exit 1; fi
test=$1
testDir=$2
myTestDir=$3

sourceDir=$testDir/$test
targetDir=$myTestDir/$test

echo -e "Source: $sourceDir"
echo -e "Target:  $targetDir"

## Remember in bash: TRUE=0, FALSE=1, unless you're using (( ))
function checkExist {
    if [ ! -e $1 ]; then echo $1 does not exist. ; return 1; else return 0; fi
}

function notCommented {
    noBlank=`echo $1 | tr -d ' '`
    if [[ $noBlank == !* ]]; then return 1; else return 0; fi
}

checkExist $sourceDir
[ $? ] || exit 1
checkExist $sourceDir/hydro.namelist
[ $? ] || exit 1

if [ ! -d $targetDir ] 
then
    mkdir -p $targetDir
    echo -e "\e[7mCreating my test directory:\e[0m \e[94m$targetDir\e[0m"
else
    echo -e "\e[7mMy test directory\e[0m \e[94m$targetDir\e[0m \e[7malready exists, updating.\e[0m"
fi

# these things have to be in the run directory
echo -e "\e[7mRun Directory Files:\e[0m"
TBLS=`ls $sourceDir/*TBL`
namelists=`ls $sourceDir/namelist.hrldas $sourceDir/hydro.namelist`
cd $targetDir
for ii in $namelists $TBLS
do
    ln -sf $ii .
    ls -l `basename $ii`
done

function linkReqFiles {
    file=$1
    cd $sourceDir
    if [[ ! -e $file ]]
    then 
        echo "No such file: $file"
        return 1
    fi
    echo -e "\e[7m $file \e[0m"
    IFS=$'\n'
    namesInFile=`egrep "('|\")" $file`

    for ii in $namesInFile
    do
        IFS=$'\n'
        cd $sourceDir
        theLines=`grep -i $ii $file`
        for jj in $theLines
        do
            notCommented $jj || continue
            echo '----------------------------------'
            theLine=`echo $jj | tr -d ' '`
            echo $theLine
            pathFile=`echo $jj | cut -d'=' -f2 | tr -d ' ' | tr -d "'" | tr -d '"'`
            thePath=`dirname $pathFile`
            theFile=`basename $pathFile`
            echo -e "\e[94m$pathFile\e[0m"
            cd $sourceDir
            cd $thePath
            if [[ ! -d $targetDir/$thePath ]]; then mkdir -p $targetDir/$thePath; fi
            ## if the file is just '.' the current directory, dont do anything once the dir is made
            if [[ "$theFile" == "." ]]; then continue; fi
            ## remove symlinks before replacing them, esp for directories
            if [[ -h $targetDir/$thePath/$theFile ]]; then rm $targetDir/$thePath/$theFile; fi
            ln -s $sourceDir/$thePath/$theFile $targetDir/$thePath/$theFile
            ls -l $targetDir/$thePath/$theFile
        done
    done
    return 0
}

echo -e "\e[7mFiles specified in the namelist files:\e[0m"
## hrldas
linkReqFiles namelist.hrldas
# hydro.namelist
linkReqFiles hydro.namelist

exit 0


