#!/bin/bash
set -e

make clean
USE_CYTHON=1 CYTHON_TRACE=1 python setup.py build_ext --inplace

echo "running flake8"
flake8 tests

echo "running pytest"
python -m coverage run --source kerl -m pytest -v $@

python -m coverage report -m
