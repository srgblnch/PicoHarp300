###############################################################################
## file :               setup.py
##
## description :        This file has been made to provide a python access to
##                      the PHLib to control a PicoHarp300 instrument.
##
## project :            TANGO
##
## author(s) :          S.Blanch-Torn\'e
##
## Copyright (C) :      2014
##                      CELLS / ALBA Synchrotron,
##                      08290 Bellaterra,
##                      Spain
##
## This file is part of Tango.
##
## Tango is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Tango is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with Tango.  If not, see <http:##www.gnu.org/licenses/>.
##
###############################################################################

from version import *

import warnings
try:
    from Cython.Distutils import build_ext
    from setuptools import setup, Extension
    HAVE_CYTHON = True
except ImportError as e:
    HAVE_CYTHON = False
    warnings.warn(e.message)
    from distutils.core import setup, Extension
    from distutils.command import build_ext

PicoHarpModule = Extension('PicoHarp',
                           define_macros = [('MAJOR_VERSION',
                                             '%d'%MAJOR_VERSION),
                                            ('MINOR_VERSION',
                                             '%d'%MINOR_VERSION),
                                            ('BUILD_VERSION',
                                             '%d'%BUILD_VERSION),
                                            ('REVISION_VERSION',
                                             '%d'%REVISION_VERSION)],
                           include_dirs = ['/usr/local/lib/ph300/'],
                           library_dirs=['/usr/lib'],
                           libraries = ['ph300'],
                           sources = ['PicoHarp.pyx'])

configuration = {'name':'PicoHarp',
                 'version':'%d.%d.%d.%d'
                            %(MAJOR_VERSION,MINOR_VERSION,
                              BUILD_VERSION,REVISION_VERSION),
                 'description': "TODO: pending",
                 'long_description':'''TODO: Long description pending''',
                 'author':"Sergi Blanch-Torn\'e",
                 'author_email':"sblanch@cells.es",
                 'install_requires': ['cython==0.11'],
                 'ext_modules': [PicoHarpModule],
                 'cmdclass': {'build_ext': build_ext}}

if not HAVE_CYTHON:
    PicoHarpModule.sources[0] = 'PicoHarp.c'
    configuration.pop('install_requires')

setup(**configuration)
