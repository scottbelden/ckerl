#!/bin/bash
set -e

this_dir=$(dirname $(readlink -f $0))

cd $this_dir/..
make clean

USE_CYTHON=1 CYTHON_PROFILE=1 python setup.py build_ext --inplace

cd $this_dir
cprofilev _profile.py
