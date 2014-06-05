###############################################################################
## file :               PicoHarp.pyx
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

cdef extern from "phlib.h":
    int PH_GetLibraryVersion(char* version)
    int PH_GetErrorString(char* errstring, int errcode)
cdef extern from "errorcodes.h":
    int ERROR_NONE
    int ERROR_DEVICE_OPEN_FAIL

def strcut(str):
    return str.split('\x00')[0]

def __version__():
    version = " "*10
    #three spaces will fit the size of the returning char*, but placed more
    # and cut it with the end string tag \x00.
    err = PH_GetLibraryVersion(version)
    if err == ERROR_NONE:
        return strcut(version)+".0"
    else:
        raise Exception("cannot get the version")

cdef extern from "phlib.h":
    int PH_OpenDevice(int devidx, char* serial)
    #int PH_CloseDevice(int devidx)
    #int PH_Initialize(int devidx, int mode)
cdef extern from "phdefin.h":
    int MAXDEVNUM

class Discoverer:
    def __init__(self):
        self._instruments = {}
        self.__getInstruments()

    def __getInstruments(self):
        sn = " "*10
        print("Searching for PicoHarp devices...")
        print("Devidx     Status")
        for i in range(MAXDEVNUM):
            err = PH_OpenDevice(i,sn)
            if err == ERROR_NONE:
                code = strcut(sn)
                print("  %1d        S/N %s"%(i,code))
                self._instruments[code] = i
            elif err == ERROR_DEVICE_OPEN_FAIL:
                print("  %1d        no device"%(i))
            else:
                Errorstring = " "*40
                PH_GetErrorString(Errorstring, err)
                print("  %1d        %s"%(i,Errorstring))

    @property
    def count(self):
        return len(self._instruments.keys())

    @property
    def serials(self):
        return self._instruments.keys()

    def search(self,serial):
        if serial in self._instruments.keys():
            return self._instruments[serial]
        else:
            raise KeyError("The serial %s is not present"%(serial))

cdef extern from "phlib.h":
    #int PH_OpenDevice(int devidx, char* serial)
    #int PH_CloseDevice(int devidx)
    int PH_Initialize(int devidx, int mode)
    int PH_GetHardwareInfo(int devidx, char* model, 
                           char* partno, char* version)
    int PH_Calibrate(int devidx)
cdef extern from "phdefin.h":
    int MODE_HIST
    #int MODE_T2
    #int MODE_T3

class Instrument:
    def __init__(self,devidx,mode=MODE_HIST):
        self._devidx = devidx
        self._mode = mode
        err = PH_Initialize(self._devidx,self._mode)
        if err != ERROR_NONE:
            raise IOError("Init error (%d)"%(err))
        print("Instrument initialised")
        self._HW_Model = " "*16
        self._HW_PartNo = " "*8
        self._HW_Version = " "*8
        err = PH_GetHardwareInfo(self._devidx,self._HW_Model,
                                 self._HW_PartNo,self._HW_Version)
        if err != ERROR_NONE:
            raise IOError("Getting hardware info error (%d)"%(err))
        print("Found Model %s Partnum %s Version %s"%(self._HW_Model,
                                                      self._HW_PartNo,
                                                      self._HW_Version))
        err = PH_Calibrate(self._devidx)
        if err != ERROR_NONE:
            raise IOError("Calibration error (%d)"%(err))
        print("Instrument calibration done")
