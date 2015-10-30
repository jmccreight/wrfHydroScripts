#!/bin/bash

## generally, select 2 or three sets of namelists/tests
## test1 : long run from t0 -> t2, restart output at t1 and t2, using C cores
##         verification: unary: NA test.  
##                       binary against reference: files test, testNLast
## test2 : restart run from t1 run to t2. Restart output at t2, using C cores.
##         verification: unary: NA test.  
##                       binary against reference: files test, testNLast
## test3 : restart run from t1 run to t2, Restart output at t2, using C-1 cores.
##         verification: unary: NA test.  
##                       binary against test2 or ref: files test, testNLast

## Just have the above identified by domain



## test1: 
## get namelists
## link to files
## run test 1
## verification: unary: NA test.  
##               binary against reference: files test, testNLast


## test2:
## get namelists
## link to files
## run test 2
## verification: unary: NA test.  
##               binary against reference: files test, testNLast


## test 3
## get namelists
## link to files
## run test 3 (with C-1 cores)
## verification: unary: NA test.  
##               binary against test2 or ref: files test, testNLast


exit 1234
