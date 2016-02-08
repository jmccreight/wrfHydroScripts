#!/bin/csh

## source this file in your .cshrc for universal access to the scripts via aliases
## source pathTo/wrfHydroScripts/sourceMe.csh

## where do you keep your scripts? This config file is required to know.
set configFile=~/.wrfHydroScripts
if (! -e $configFile) then
    echo \
    "\e[31mPlease create a ~/.wrfHydroScripts file based on the example in the repository.\e[0m"
    exit 1
endif

set whsPath=`grep "wrfHydroScripts" $configFile | cut -d '=' -f2 | tr -d ' '` 

alias henv 'printenv | egrep -i "(HYDRO|NUDG|PRECIP|CHAN_CONN|^NETCDF|^LDFLAGS|^ifort|REALTIME|SOIL)" | egrep -v PWD'

alias hgrep '$whsPath/hgrep.sh'

alias plotFrxst '$whsPath/plotFrxst.sh'

alias cleanup '$whsPath/cleanup.sh'

alias cleanRun '$whsPath/cleanRun.sh'

alias linkToTestCase '$whsPath/linkToTestCase.sh'

alias standardizeTestCase '$whsPath/standardizeTestCase.sh'

alias getTestFiles '$whsPath/getTestFiles.sh'

alias testNLast '$whsPath/testNLast.sh'

alias makeCheck '$whsPath/makeCheck.sh'

alias qCleanRun '$whsPath/qCleanRun.sh'

alias bCleanRun '$whsPath/bCleanRun.sh'

alias compileAll '$whsPath/compileAll.sh'

alias regTest '$whsPath/regTest.sh'

alias compileTag '$whsPath/compileTag.sh'

alias geyser '$whsPath/geyser.sh'

exit  0
