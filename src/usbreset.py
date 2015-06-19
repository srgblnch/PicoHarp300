###############################################################################
## file :               usbreset.py
##
## description :        This file has been made to solve communication issues
##                      with the PicoHarp300 instrument.
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

import os
from subprocess import Popen, PIPE

class usbreset:
    def __init__(self,
                 sysDirectory = '/sys/bus/pci/drivers/',
                 driver = 'ehci_hcd'):
        self._sysDirectoryPath = sysDirectory
        self._driverName = driver
        self._usbCode = None
        self.findDevice()

    @property
    def sysDirectory(self):
        return self._sysDirectoryPath

    @sysDirectory.setter
    def sysDirectory(self,value):
        self._sysDirectoryPath = value

    @property
    def driverName(self):
        return self._driverName

    @driverName.setter
    def driverName(self,value):
        self._driverName = value

    @property
    def usbpath(self):
        return self._sysDirectoryPath+self._driverName
    
    @property
    def usbCode(self):
        return self._usbCode

    def findDevice(self):
        fileNames = os.listdir(self.usbpath)
        for name in fileNames:
            if len(name) == 12 and \
            name.find(':') == 4 and \
            name.rfind(':') == 7 and \
            name.find('.') == 10:
                self._usbCode = name
    
    def check_lsusb(self):
        lsusb_out = Popen("lsusb -t", shell=True, bufsize=64,
                          stdin=PIPE, stdout=PIPE,close_fds=True)\
                          .stdout.read().strip()
        return lsusb_out
    
    def unbind(self):
        with open(self.usbpath+'/unbind','w') as f:
            f.write(self._usbCode)
    
    def bind(self):
        with open(self.usbpath+'/bind','w') as f:
            f.write(self._usbCode)

def main():
    obj = usbreset()
    print("Found %s"%(obj.usbCode))
    obj.unbind()
    print("Unbind...")
    obj.check_lsusb()
    obj.bind()
    print("bind...")
    obj.check_lsusb()

if __name__ == '__main__':
    main()
