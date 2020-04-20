#!/bin/bash
set -e
set -x
module load matlab/2019a
module unload gcc
module load gcc/6.1.0
#mex -O Csource/nearpoints32.cxx
mex -O Csource/myCinterp3.c
