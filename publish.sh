#!/bin/bash
# Push to pypi and tag

version=$(python setup.py --version)

# Fail on 1'st error
set -e
set -x

rm -rf dist/

make fresh
USE_CYTHON=1 python setup.py sdist

twine upload dist/ckerl-${version}.tar.gz

git tag -f ${version}
git push
git push --tags
