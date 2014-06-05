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

from version import MAJOR_VERSION,MINOR_VERSION,BUILD_VERSION,REVISION_VERSION
import time
cimport cython
from libc.stdlib cimport malloc, free
#cimport numpy as np

cdef extern from "phlib.h":
    int PH_GetErrorString(char* errstring, int errcode)

class Logger:
    '''Very basic debugging flag mode
    '''
    def __init__(self,debug):
        self.__debug = debug
    def debug(self,msg):
        if self.__debug:
            print(msg)
    def interpretError(self,err):
        ErrorString = " "*40
        PH_GetErrorString(ErrorString, err)
        return ErrorString

cdef extern from "phlib.h":
    int PH_GetLibraryVersion(char* version)
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
        return strcut(version)+".%d-%d"%(BUILD_VERSION,REVISION_VERSION)
    else:
        raise Exception("cannot get the version")

cdef extern from "phlib.h":
    int PH_OpenDevice(int devidx, char* serial)
cdef extern from "phdefin.h":
    int MAXDEVNUM

class Discoverer(Logger):
    def __init__(self,debug=False):
        Logger.__init__(self, debug)
        self._instruments = {}
        self.__getInstruments()

    def __getInstruments(self):
        '''Iterate between the possible IDs, looking for plugged instruments.
           If there is some, try to get the serial or in case of error, 
           interpret the returned error.
        '''
        sn = " "*10
        self.debug("Searching for PicoHarp devices...")
        self.debug("Devidx     Status")
        for i in range(MAXDEVNUM):
            err = PH_OpenDevice(i,sn)
            if err == ERROR_NONE:
                code = strcut(sn)
                self.debug("  %1d        S/N %s"%(i,code))
                self._instruments[code] = i
            elif err == ERROR_DEVICE_OPEN_FAIL:
                self.debug("  %1d        no device"%(i))
            else:
                #Errorstring = " "*40
                #PH_GetErrorString(Errorstring, err)
                self.debug("  %1d        %s"%(i,self.interpretError(err)))

    @property
    def count(self):
        '''Returns how many instruments have been found.
        '''
        return len(self._instruments.keys())

    @property
    def serials(self):
        '''List of all the serial numbers found
        '''
        return self._instruments.keys()

    def search(self,serial):
        '''Given a serial of an instrument, get its ID.
           Or exception if it's not present
        '''
        if serial in self._instruments.keys():
            return self._instruments[serial]
        else:
            raise KeyError("The serial %s is not present"%(serial))

cdef extern from "phlib.h":
    #int PH_OpenDevice(int devidx, char* serial)
    int PH_CloseDevice(int devidx)
    int PH_Initialize(int devidx, int mode)
    int PH_GetHardwareInfo(int devidx, char* model, 
                           char* partno, char* version)
    int PH_Calibrate(int devidx)
    int PH_SetSyncDiv(int devidx, int div)
    int PH_SetInputCFD(int devidx, int channel, int level, int zc)
    int PH_SetBinning(int devidx, int binning)
    int PH_SetOffset(int devidx, int offset)
    int PH_GetResolution(int devidx, double* resolution)
    int PH_GetCountRate(int devidx, int channel, int* rate)
    int PH_SetStopOverflow(int devidx, int stop_ovfl, int stopcount)
    int PH_ClearHistMem(int devidx, int block)
    int PH_StartMeas(int devidx, int tacq)
    int PH_StopMeas(int devidx)
    int PH_CTCStatus(int devidx, int* ctcstatus)
    int PH_GetHistogram(int devidx, unsigned int* chcount, int block)
    int PH_GetFlags(int devidx, int* flags)
cdef extern from "phdefin.h":
    int MODE_HIST
    #int MODE_T2
    #int MODE_T3
    int HISTCHAN
    int FLAG_OVERFLOW
    int ZCMIN
    int ZCMAX
    int DISCRMIN
    int DISCRMAX

class Instrument(Logger):
    def __init__(self,devidx,mode=MODE_HIST,divider=8,binning=0,offset=0,
                 acqTime=1000,block=0,CFDLevels=[100,100],CFDZeroCross=[10,10],
                 debug=False):
        Logger.__init__(self, debug)
        self._devidx = devidx
        if mode != MODE_HIST:
            raise NotImplementedError("Only histogram mode supported")
        self._mode = mode
        self.initialise()
        self._HW_Model = " "*16
        self._HW_PartNo = " "*8
        self._HW_Version = " "*8
        self.__getHardwareInfo()
        self.__calibrate()
        #configurable parameters
        self._SyncDivider = divider
        if CFDLevels[0] < DISCRMIN or CFDLevels[1] < DISCRMIN:
            raise ValueError("CFD levels must be above %d"%(DISCRMIN))
        if CFDLevels[0] > DISCRMAX or CFDLevels[1] > DISCRMAX:
            raise ValueError("CFD levels must be below %d"%(DISCRMAX))
        self._CFDLevel = CFDLevels
        if CFDZeroCross[0] < ZCMIN or CFDZeroCross[1] < ZCMIN:
            raise ValueError("CFD zero cross must be above %d"%(ZCMIN))
        if CFDZeroCross[0] > ZCMAX or CFDZeroCross[1] > ZCMAX:
            raise ValueError("CFD zero cross must be below %d"%(ZCMAX))
        self._CFDZeroCross = CFDZeroCross
        self._Binning = binning
        self._Offset = offset
        self._acquisitionTime = acqTime#ms
        self._block = block
        #readonly parameters
        self._Resolution = 0.0
        #outputs
        self._CountRate = [0,0]
        self._counts = [0]*HISTCHAN
        self._flags = 0
        self._integralCount = 0.0
        self.prepare()

    def prepare(self):
        self.debug("Preparing the instrument to acquire.")
        self.setSyncDivider()
        self.setInputCFD(0)
        self.setInputCFD(1)
        self.setBinning()
        self.setOffset()
        self.getResolution()
        self.getCountRates()
        #From dlldemo.c: after Init or SetSyncDiv you must allow 100 ms 
        #for valid new count rate readings.
        time.sleep(0.2)#200ms
        self.setStopOverflow()

    def acquire(self):
        self.clearHistMem()
        self.getCountRates()
        self.startMeas()
        waitloop = 0
        while(self.getCounterStatus()==0):
            waitloop += 1
        self.stopMeas()
        self.getHistogram()
        self.getFlags()
        self.integralCount()
        self.debug("waitloop = %d total count = %d"
                   %(waitloop,self._integralCount))
        if (self._flags&FLAG_OVERFLOW):
            self.debug("Overflow!")

    def __del__(self):
        err = PH_CloseDevice(self._devidx)
        if err != ERROR_NONE:
            raise IOError("Close error (%d)"%(err))
        self.debug("Instrument connection closed.")

    def initialise(self):
        err = PH_Initialize(self._devidx,self._mode)
        if err != ERROR_NONE:
            raise IOError("Init error (%d): %s"%(err,self.interpretError(err)))
        self.debug("Instrument initialised.")

    def __getHardwareInfo(self):
        err = PH_GetHardwareInfo(self._devidx,self._HW_Model,
                                 self._HW_PartNo,self._HW_Version)
        if err != ERROR_NONE:
            raise IOError("Getting hardware info error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Found Model %s Partnum %s Version %s"%(self._HW_Model,
                                                           self._HW_PartNo,
                                                           self._HW_Version))
        self._HW_Model = strcut(self._HW_Model)
        self._HW_PartNo = strcut(self._HW_PartNo)
        self._HW_Version = strcut(self._HW_Version)
    def __calibrate(self):
        err = PH_Calibrate(self._devidx)
        if err != ERROR_NONE:
            raise IOError("Calibration error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Instrument calibration done.")

    @property
    def __model__(self):
        return self._HW_Model

    @property
    def __partnum__(self):
        return self._HW_PartNo

    @property
    def __version__(self):
        return self._HW_Version

    def getSyncDivider(self):
        return self._SyncDivider
    def setSyncDivider(self,syncDivider=None):
        if syncDivider == None:
            syncDivider = self._SyncDivider
        err = PH_SetSyncDiv(self._devidx,syncDivider)
        if err != ERROR_NONE:
            raise IOError("SetSyncDiv error (%d): %s"
                          %(err,self.interpretError(err)))
        self._SyncDivider = syncDivider
        self.debug("SetSyncDiv has been set (%d)"%(self._SyncDivider))
    
    #TODO: a getter
    def setInputCFD(self,channel,CFDZeroCross=None,CFDLevel=None):
        if CFDZeroCross == None:
            CFDZeroCross = self._CFDZeroCross[channel]
        if CFDLevel == None:
            CFDLevel = self._CFDLevel[channel]
        if CFDLevel < DISCRMIN:
            raise ValueError("CFD levels must be above %d"%(DISCRMIN))
        if CFDLevel > DISCRMAX:
            raise ValueError("CFD levels must be below %d"%(DISCRMAX))
        if CFDZeroCross < ZCMIN:
            raise ValueError("CFD zero cross must be above %d"%(ZCMIN))
        if CFDZeroCross > ZCMAX:
            raise ValueError("CFD zero cross must be below %d"%(ZCMAX))
        err = PH_SetInputCFD(self._devidx,channel,CFDLevel,CFDZeroCross)
        if err != ERROR_NONE:
            raise IOError("setInputCFD error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("setInputCFD has been set for channel %d: "\
                   "(CFDLevel:%d,CFDZeroCross:%d)"
                   %(channel,CFDLevel,CFDZeroCross))
        self._CFDZeroCross[channel] = CFDZeroCross
        self._CFDLevel[channel] = CFDLevel

    def getBinning(self):
        return self._Binning
    def setBinning(self,Binning=None):
        if Binning == None:
            Binning = self._Binning
        err = PH_SetBinning(self._devidx,Binning)
        if err != ERROR_NONE:
            raise IOError("SetBinning error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Binning = Binning
        self.debug("Binning = %d"%(self._Binning))
        
    def getOffset(self):
        return self._Offset
    def setOffset(self,Offset=None):
        if Offset == None:
            Offset = self._Offset
        err = PH_SetOffset(self._devidx,Offset)
        if err != ERROR_NONE:
            raise IOError("SetOffset error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Offset = Offset
        self.debug("Offset = %d"%(self._Offset))

    def getResolution(self):
        cdef double resolution = 0.0
        err = PH_GetResolution(self._devidx,&resolution)
        if err != ERROR_NONE:
            raise IOError("GetResolution error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Resolution = resolution
        self.debug("Resolution = %g"%(self._Resolution))
        return self._Resolution
    #There is no setter
    
    def getCountRate(self,channel):
        cdef int countrate = 0
        err = PH_GetCountRate(self._devidx,channel,&countrate)
        if err != ERROR_NONE:
            raise IOError("GetCountRate channel %d error (%d): %s"
                          %(channel,err,self.interpretError(err)))
        self._CountRate[channel] = countrate
        self.debug("CountRate[%d] = %d"%(channel,self._CountRate[channel]))
        return countrate
    def getCountRates(self,channel=None):
        if channel == None:
            channel = [0,1]
        elif channel in [0,1]:
            channel = [channel]
        else:
            raise IndexError("Channel not well specified.")
        for i in channel:
            self.getCountRate(i)
        return self._CountRate
    
    def setStopOverflow(self):
        err = PH_SetStopOverflow(self._devidx,1,HISTCHAN-1)
        if err != ERROR_NONE:
            raise IOError("SetStopOverflow error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Overflow stopper set")

    def getBlock(self):
        return self._block
    def setBlock(self,block):
        self._block = block

    def clearHistMem(self,block=None):
        if block == None:
            block = self._block
        err = PH_ClearHistMem(self._devidx,block)
        if err != ERROR_NONE:
            raise IOError("ClearHistMem error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Histogram memory (block %d) clean"%(block))

    def getAcquisitionTime(self):
        return self._acquisitionTime
    def setAcquisitionTime(self,AcquisitionTime):
        self._acquisitionTime = AcquisitionTime

    def startMeas(self,AcquisitionTime=None):
        if AcquisitionTime == None:
            AcquisitionTime = self._acquisitionTime
        err = PH_StartMeas(self._devidx,AcquisitionTime)
        if err != ERROR_NONE:
            raise IOError("StartMeas error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("start measurement")
    
    def getCounterStatus(self):
        cdef int ctcstatus=0
        err = PH_CTCStatus(self._devidx,&ctcstatus)
        if err != ERROR_NONE:
            raise IOError("CTCStatus error (%d): %s"
                          %(err,self.interpretError(err)))
        #self.debug("counter status = %d"%(ctcstatus))
        return ctcstatus

    def stopMeas(self):
        err = PH_StopMeas(self._devidx)
        if err != ERROR_NONE:
            raise IOError("StopMeas error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("stop measurement")

    def getHistogram(self,block=None):
        if block == None:
            block = self._block
        #cdef np.ndarray[np.uint32_t, ndim=1] counts = np.zeros([HISTCHAN],
        #                                                      dtype=np.uint32)
        cdef unsigned int *counts
        counts = <unsigned int*>malloc(HISTCHAN*cython.sizeof(int))
        err = PH_GetHistogram(self._devidx,counts,block)
        if err != ERROR_NONE:
            raise IOError("GetHistogram error (%d): %s"
                          %(err,self.interpretError(err)))
        for i in xrange(len(self._counts)):
            self._counts[i] = counts[i]
        free(counts)
        if len(self._counts)>21:
            self.debug("Histogram (block %d): %s (...) %s"
                       %(block,repr(self._counts[:7])[:-1],
                         repr(self._counts[-7:])[1:]))
        else:
            self.debug("Histogram (block %d): %s"%(block,self._counts))
        return self._counts

    def getFlags(self):
        cdef int flags = 0
        err = PH_GetFlags(self._devidx,&flags)
        if err != ERROR_NONE:
            raise IOError("GetFlags error (%d): %s"
                          %(err,self.interpretError(err)))
        self._flags = flags
        self.debug("Flags: %s"%(bin(self._flags)))
        return self._flags

    def integralCount(self):
        integralCount = 0
        for count in self._counts:
            integralCount += count
        self._integralCount = integralCount
        self.debug("Integral count = %d"%(self._integralCount))
        return self._integralCount
