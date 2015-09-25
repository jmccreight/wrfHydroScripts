#!/bin/bash

## Purpose: to "duplicate" via symlinks someone else's (you dont have 
## permission in their run dir) WRF-Hydro test case. You want all their 
## dependencies as specified in their namelists (and really nothing more)
## and all the run dependencies (namelists and *TBL files).

## Arguments:
## takes a single argument, the name of the test you want to link to relative to $testDir
inDir=$1
## Parameters:
## these two could be taken as arguments eventually:
testDir=/d2/weiyu/TESTING/$inDir
myTestDir=/d6/jamesmcc/WRF_Hydro/TESTING/Wei/$inDir

## Remember in bash: TRUE=0, FALSE=1, unless you're using (( ))
function checkExist {
    if [ ! -e $1 ]; then echo $1 does not exist. ; return 1; else return 0; fi
}

function notCommented {
    noBlank=`echo $1 | tr -d ' '`
    if [[ $noBlank == !* ]]; then return 1; else return 0; fi
}

checkExist $testDir || exit 1
checkExist $testDir/hydro.namelist || exit 1

if [ ! -d $myTestDir ] 
then
    mkdir -p $myTestDir
    echo -e "\e[7mCreating my test directory:\e[0m \e[94m$myTestDir\e[0m"
else
    echo -e "\e[7mMy test directory\e[0m \e[94m$myTestDir\e[0m \e[7malready exists, updating.\e[0m"
fi

# these things have to be in the run directory
echo -e "\e[7mRun Directory Files:\e[0m"
TBLS=`ls $testDir/*TBL`
namelists=`ls $testDir/namelist.hrldas $testDir/hydro.namelist`
cd $myTestDir
for ii in $namelists $TBLS
do
    ln -sf $ii .
    ls -l `basename $ii`
done

function linkReqFiles {
    file=$1
    cd $testDir
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
        cd $testDir
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
            cd $testDir
            cd $thePath
            if [[ ! -d $myTestDir/$thePath ]]; then mkdir -p $myTestDir/$thePath; fi
            ## if the file is just '.' the current directory, dont do anything once the dir is made
            if [[ "$theFile" == "." ]]; then continue; fi
            ## remove symlinks before replacing them, esp for directories
            if [[ -h $myTestDir/$thePath/$theFile ]]; then rm $myTestDir/$thePath/$theFile; fi
            ln -s $testDir/$thePath/$theFile $myTestDir/$thePath/$theFile
            ls -l $myTestDir/$thePath/$theFile
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


