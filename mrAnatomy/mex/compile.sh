#!/bin/bash

module load matlab/2019a
module unload gcc
module load gcc/6.1.0

set -e
set -x
mex -O Csource/nearpoints.cxx
#mex -O Csource/myCinterp3.cxx
