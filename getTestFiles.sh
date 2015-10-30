#!/bin/bash

## setup helpers

#1 = rundirectory
runDir=`getAbsPath $1`
checkExist $runDir || exit 1

#2 = testFileDir or testFileName
testFileDir=`getAbsPath $2`
checkExist $testFileDir || exit 1

cd $runDir

## PARAMS
## symlink the directory over and then copy out the 
## params to the run dir.
if [ -e PARAMS ]; then rm -rf PARAMS; fi
ln -s $testFileDir/PARAMS .
for pp in PARAMS/*
do
    basePp=`basename $pp`
    ln -sf $pp $basePp
    chmod 555 $basePp
done

## DOMAIN
## Check for existing DOMAIN, create it if it does not exist. 
## Link files into DOMAIN warning of conflicts.



exit 0
