#!/bin/bash
set -e
set -x
module load matlab/2017a
module unload gcc
module load gcc/4.9.4
mex -O Csource/nearpoints32.cxx

