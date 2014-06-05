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

MAJOR_VERSION,MINOR_VERSION = 3,0#this comes from the phlib
BUILD_VERSION = 0
#REVISION_VERSION = 0

from distutils.core import setup, Extension

PicoHarpModule = Extension('PicoHarp',
                           define_macros = [('MAJOR_VERSION',
                                             '%d'%MAJOR_VERSION),
                                            ('MINOR_VERSION',
                                             '%d'%MINOR_VERSION),
                                            ('BUILD_VERSION',
                                             '%d'%BUILD_VERSION)],
                           include_dirs=['/usr/local/lib/ph300/'],
                           library_dirs=['/usr/lib'],
                           libraries = ['ph300'],
                           sources = ['PicoHarp.c']
                          )

setup(name = 'PicoHarp',
      version = '%d.%d.%s'%(MAJOR_VERSION,MINOR_VERSION,BUILD_VERSION),
      description = "TODO: pending",
      long_description = '''TODO: Long description pending''',
      author = "Sergi Blanch-Torn\'e",
      author_email = "sblanch@cells.es",
      ext_modules = [PicoHarpModule]
     )