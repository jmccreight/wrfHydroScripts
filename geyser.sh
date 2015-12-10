#!/bin/bash
bsub -Is -q geyser -W 24:00 -n 1 -P P48500028 -J "geyser" $SHELL
exit $?
