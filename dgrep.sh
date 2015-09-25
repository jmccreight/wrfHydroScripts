#!/bin/bash

searchStr=("$@")

echo "${searchStr[@]}"

cd ~/DART/wrfHydro/
grep -s "${searchStr[@]}" */*.f90
grep -s "${searchStr[@]}" */*/*.f90
grep -s "${searchStr[@]}" */*/*/*.f90
grep -s "${searchStr[@]}" */*/*/*/*.f90

exit 0
