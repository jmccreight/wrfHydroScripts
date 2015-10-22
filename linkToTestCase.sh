#!/bin/bash

help='

linkToTestCase.sh :: help

Purpose: to "duplicate" via symlinks someone elses (you dont have 
permission in their run dir) WRF-Hydro test case. You want all their 
dependencies as specified in their namelists (and really nothing more)
and all the run dependencies (namelists and *TBL files).

Options:
 -c Copy instead of link **all files but DOMAIN and forcings**. Useful when you 
    want to extract/establish a test case from an existing directory where other 
    stuff may live or run different instances of the same domain in different
    run directories but change the namelist and other dependencies besides
    forcings while the runs are occuring.
 -f force copy of forcing files: -cdf copies all model dependencies. 
 -d force copy of DOMAIN files: -cdf copies all model dependencies. (Note 
    that these are recognized by the names currently used in the namelists, 
    not by their placement in a DOMAIN/ folder.
 -n Get nudging files: for nudging -cdfn copies all model dependencies when nudging.
 -p write protect the results.
 -u un-write protect and clobber write protected files

Arguments:
 1) ($test) The name of the test you want to link to relative to $testDir, could be 
     several directories deep, e.g. testFOO/fooBAR
 2) The test directory, $testDir, where the source test lives, 
     e.g. /home/someTester/TESTS then the tests from 1 would be
     /home/someTester/TESTS/testFOO/fooBAR
 3) "$myTestDir"  the directory into which the test is to be "copied",
     e.g. /home/myself/TESTS/specialTest the above examples would result in
     /home/myself/TESTS/specialTest/testFOO/fooBAR
'

## TODO: allow relative paths?

## NOTES:
## NOTE WELL
## cp has to be one of the starngest commands in the liberties it takes with permissions: 
##   1) cp --remove-destination disrepsects permissions! so write this.
##   2) you can cp -r OVER a write protected dir, you cant normally touch files in a wp dir.

## bring in some functions
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

###################################
## OPTIONS
# Defaults first
linkOrCopy='link'  
getNudgingFiles=1  ## FALSE
writeProtect=1     ## FALSE
unWriteProtect=1   ## FALSE
linkForc=0         ## TRUE 
linkDomain=0         ## TRUE 
while getopts ":fpuncd" opt; do
  case $opt in
    u)
      echo -e "\e[41mUN-Write protecting files.\e[0m"
      echo -e "\e[41mDo you want to do this? Enter 'yes' to continue:\e[0m"
      read unProtectQuery
      if [[ ! $unProtectQuery == "yes" ]]
      then 
          echo 'You did not answer "yes", aborting.'
          exit 1
      fi
      unWriteProtect=0
      ;;
    c)
      echo -e "\e[46mCopying files instead of linking (but not DOMAIN or FORCING files).\e[0m"
      linkOrCopy='copy'
      ;;
    f)
      echo -e "\e[46mCopying FORCING files instead of linking.\e[0m"
      linkForc=1
      ;;
    d)
      echo -e "\e[46mCopying DOMAIN files instead of linking.\e[0m"
      linkDomain=1
      ;;
    n)
      echo -e "\e[46mGetting nudging files.\e[0m"
      getNudgingFiles=0
      ;;
    p)
      echo -e "\e[101mWrite protecting files.\e[0m"
      writeProtect=0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

###################################
## ARGUMENTS
if [ -z "$1" ] | [ -z "$2" ] | [ -z "$3" ]; then echo -e "Argument(s) missing. $help"; exit 1; fi
test=$1
testDir=`getAbsPath $2`
myTestDir=`getAbsPath $3`

###################################
## setup and basic checks
sourceDir=$testDir/$test
targetDir=$myTestDir/$test

echo -e "Source: $sourceDir"
echo -e "Target:  $targetDir"

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

###################################
## Run dir stuff
# these things have to be in the run directory
echo -e "\e[7mRun Directory Files:\e[0m"
TBLS=`ls --color=auto $sourceDir/*TBL`
namelists=`ls --color=auto $sourceDir/namelist.hrldas $sourceDir/hydro.namelist`
if [[ $"getNudgingFiles" -eq 0 ]]
then
    nudgeFiles=`ls -d $sourceDir/nudgingTimeSliceObs $sourceDir/nudgingParams.nc`
    ## This one is definitely going to move into namelist and evnetually get picked up in the 
    ## next section
    nudgeFiles="$nudgeFiles "`ls -d $sourceDir/netwkReExFile.nc`
else 
    nudgeFiles=''
fi
echo $namesInFile

if [[ $unWriteProtect -eq 0 ]]; then chmod 755 $targetDir/; fi
if [[ $unWriteProtect -eq 0 ]]; then chmod 755 $targetDir/*; fi

cd $targetDir
for ii in $namelists $TBLS $nudgeFiles
do
    theSource=$ii
    #since all targets go in targetDir
    theTarget=`basename $ii`  
    if [[ $unWriteProtect -eq 0 ]]; then chmod 755 $theTarget; fi
    if [[ $linkOrCopy == 'link' ]]
    then
        ln -sf $theSource .
    else 
        if [[ -d $theSource ]] ## directory
        then
            ## cp --remove-destination disrepsects permissions! so write this.
            if [[ -h $theTarget ]]; then rm -r $theTarget; fi  ## if symlink 
            cp -rH $theSource .
        else
            if [[ -h $theTarget ]]; then rm $theTarget; fi  ## if symlink
            cp -H $theSource .
        fi
    fi
    if [[ $writeProtect -eq 0 ]]; then chmod 555 $theTarget; fi
    ## why in god's name you can cp -r OVER a write protected dir, i do not know.
    if [[ -d $theSource ]]; then chmod 555 $theTarget/*; fi
    ls -dl --color=auto $theTarget
done

###################################
## function to get things referenced in namelists
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
l
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
            nlstItem=`echo $jj | cut -d'=' -f1 | tr -d ' '`
            pathFile=`echo $jj | cut -d'=' -f2 | tr -d ' ' | tr -d "'" | tr -d '"'`
            thePath=`dirname $pathFile`
            theFile=`basename $pathFile`
            echo -e "\e[94m$pathFile\e[0m"
            cd $sourceDir
            cd $thePath
            if [[ ! -d $targetDir/$thePath ]]; then mkdir -p $targetDir/$thePath; fi
            ## if the file is just '.' the current directory, dont do anything once the dir is made
            if [[ "$theFile" == "." ]]; then continue; fi
            if [[ $unWriteProtect -eq 0 ]]; then chmod 755 $targetDir/$thePath/$theFile; fi
            if [[ $linkOrCopy == 'link' ]] 
            then
                ## remove symlinks before replacing them, esp for directories
                if [[ -h $targetDir/$thePath/$theFile ]]; then rm $targetDir/$thePath/$theFile; fi
                ln -s $sourceDir/$thePath/$theFile $targetDir/$thePath/$theFile
            else 
                ## Either: require -f flag to force copy of forcings, otherwise always link them
                [[ $nlstItem == "INDIR" ]] && [[ $linkForc -eq 0 ]]
                test1=$?
                ## Or: require -d flag to force copy of DOMAIN/ files, otherwise always link them
                domainSet='HRLDAS_SETUP_FILE GEO_STATIC_FLNM GEO_FINEGRID_FLNM'
                domainSet="${domainSet} route_link_f GWBUCKPARM_file gwbasmskfil udmap_file"
                isInSet "$nlstItem" "$domainSet" && [[ $linkDomain -eq 0 ]]
                test2=$?
                if [ $test1 -eq 0 ] || [ $test2 -eq 0 ]  ## or
                then 
                    if [[ -h $targetDir/$thePath/$theFile ]]; then rm $targetDir/$thePath/$theFile; fi
                    ln -s $sourceDir/$thePath/$theFile $targetDir/$thePath/$theFile
                else 
                    ## cp --remove-destination is BAD, disrespects permissions
                    if [[ -h $targetDir/$thePath/$theFile ]]; then rm $targetDir/$thePath/$theFile; fi
                    cp -rH $sourceDir/$thePath/$theFile $targetDir/$thePath/$theFile
                fi
            fi
            if [[ $writeProtect -eq 0 ]]; then chmod 555 $targetDir/$thePath/$theFile; fi
            ls -dl --color=auto $targetDir/$thePath/$theFile
        done
    done
    return 0
}

###################################
## call the function
echo -e "\e[7mFiles specified in the namelist files:\e[0m"
## hrldas
linkReqFiles namelist.hrldas
# hydro.namelist
linkReqFiles hydro.namelist

if [[ $writeProtect -eq 0 ]]; then chmod 555 $targetDir/*; fi
if [[ $writeProtect -eq 0 ]]; then chmod 555 $targetDir/; fi

## fix: make a summary of where all copies/links point?

exit 0


