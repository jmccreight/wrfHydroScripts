#!/bin/bash

## Purpose: make scanning for problems/errors in re-compilation much faster/easier.
## This is NOT intended to be used for the initial compilation.
## e.g. do the following 
## ./configure 2
## ./compile_offline_NoahMP.chs
## makeCheck
## cat make.log
## makeCheck
## cat make.log
## makeCheck
## cat make.log

date +'%H:%M:%S'
make &> make.log

count=0



illegals=`grep -i 'illegal' make.log`
if [ $? -eq 0 ] 
then
    echo -e "\e[44m-- illegals --\e[0m"
    echo -e "\e[34m$illegals\e[0m"
    ((count++))
fi

warnDontShow="(warning: extra tokens at end of #endif directive)"
warns=`grep -i 'warn' make.log | egrep -v "$dontShow"`

if [ $? -eq 0 ] 
then
    echo -e "\e[43m++ warns ++\e[0m"
    echo -e "\e[33m$warns\e[0m"
    ((count++))
fi

errors=`grep -i 'error' make.log`
if [ $? -eq 0 ] 
then
    echo -e "\e[41m** errors **\e[0m"
    echo -e "\e[31m$errors\e[0m"
    ((count++))
fi

if [ "$count" -gt 0 ] 
then
    echo -e "\e[46m See make.log \e[0m"
fi

exit $count
