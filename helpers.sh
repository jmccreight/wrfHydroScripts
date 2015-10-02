#!/bin/bash

## Remember in bash: TRUE=0, FALSE=1, unless you're using (( ))

function checkExist {
    if [ ! -e $1 ]; then echo $1 does not exist. ; return 1; else return 0; fi
}

function notCommented {
    noBlank=`echo $1 | tr -d ' '`
    if [[ $noBlank == !* ]]; then return 1; else return 0; fi
}

function getAbsPath {
    if [[ ! "$1" = /* ]]; then echo `pwd`/$1; else echo $1; fi
}

function henv {
    printenv | egrep -i "(HYDRO|NUDG|PRECIP|CHAN_CONN|^NETCDF|^LDFLAGS|^ifort)" | egrep -v PWD
}
