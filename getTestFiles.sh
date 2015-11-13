#!/bin/bash

## fix: "clobber" option.

## setup helpers
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

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
if [ -e PARAMS ]; 
then
    if [ -h PARAMS ]; 
    then 
        rm -rf PARAMS; 
    else
        echo -e "The PARAMS direectory was not a symlink. Aborting to protect your files."
        exit 1
    fi  ## clobber?!
fi
    
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
if [ -e DOMAIN ]; 
then
    if [ -h DOMAIN ]; 
    then 
        rm -rf DOMAIN; 
    else
        echo -e "The DOMAIN direectory was not a symlink. Aborting to protect your files."
        exit 1
    fi  ## clobber?!
fi

ln -s $testFileDir/DOMAIN .


cp $testFileDir/namelist.hrldas  namelist.hrldas.testFileTemplate
cp $testFileDir/hydro.namelist   hydro.namelist.testFileTemplate

exit 0
