#!/usr/bin/env python
# coding=utf-8

import os
from os.path import abspath, dirname, join
from setuptools import setup, Extension

if os.getenv('USE_CYTHON'):
    USE_CYTHON = True
else:
    USE_CYTHON = False

ext = '.pyx' if USE_CYTHON else '.c'

if os.getenv('CYTHON_TRACE'):
    macros = [('CYTHON_TRACE', '1')]
    from Cython.Compiler.Options import get_directive_defaults
    get_directive_defaults()['linetrace'] = True
else:
    macros = []

if os.getenv('CYTHON_PROFILE'):
    from Cython.Compiler.Options import get_directive_defaults
    get_directive_defaults()['profile'] = True

ext_modules = [
    Extension('kerl.kerl', ['kerl/kerl' + ext], define_macros=macros),
    Extension('kerl.conv', ['kerl/conv' + ext], define_macros=macros),
]

setup_dir = abspath(dirname(__file__))
with open(join(setup_dir, 'requirements.txt')) as fp:
    install_requires = fp.readlines()

setup(
    name = 'kerl',
    description = 'Cython implementation of Kerl',
    url = 'https://github.com/scottbelden/kerl',
    version = '1.0.0',
    packages = ['kerl'],
    ext_modules = ext_modules,
    install_requires = install_requires,
    include_package_data  = True,
    license = 'MIT',
    author        = 'Scott Belden',
    author_email  = 'scottabelden@gmail.com',
)