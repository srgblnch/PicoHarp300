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

from version import version,BUILD_VERSION,REVISION_VERSION
from time import sleep
from datetime import datetime,timedelta
cimport cython
#from libc.stdlib cimport calloc, free
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from threading import Thread,Event,currentThread
import random #used in the simulator
#cimport numpy as np #used in the simulator

cdef extern from "phlib.h":
    int PH_GetErrorString(char* errstring, int errcode)

def __strcut(str):
    '''This is an internal method used with the returning strings from c. The
       strings are defined as char[N] and the return don't stop with on the 
       \000 and it's what this method does.
    '''
    return str.split('\x00')[0]

ERROR   = 1
WARNING = 2
INFO    = 3
DEBUG   = 4

ACQ_MONITOR_T = 0.1

class Logger:
    '''This class is a very basic debugging flag mode used as a super class
       for the other classes in this library.
    '''
    type = {ERROR:  'ERROR',
            WARNING:'WARNING',
            INFO:   'INFO',
            DEBUG:  'DEBUG'}
    def __init__(self,debug):
        self.__debug = debug
    @property
    def _threadId(self):
        return currentThread().getName()
    def _print(self,msg,type):
        when = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
        print("%10s\t%s\t%s\t%s\t%s"%(self._threadId,type,when,self._name,msg))
    def error(self,msg):
        self._print(msg,self.type[ERROR])
    def warning(self,msg):
        self._print(msg,self.type[WARNING])
    def info(self,msg):
        self._print(msg,self.type[INFO])
    def debug(self,msg):
        if self.__debug:
            self._print(msg,self.type[DEBUG])
    def interpretError(self,err):
        ErrorString = " "*40
        PH_GetErrorString(ErrorString, err)
        errStr = __strcut(ErrorString)
        self.debug("interpretError(%d): %s"%(err,errStr))
        return errStr

cdef extern from "phlib.h":
    int PH_GetLibraryVersion(char* version)
cdef extern from "errorcodes.h":
    int ERROR_NONE
    int ERROR_DEVICE_OPEN_FAIL
    int ERROR_DEVICE_BUSY
    int ERROR_DEVICE_HEVENT_FAIL
    int ERROR_DEVICE_CALLBSET_FAIL
    int ERROR_DEVICE_BARMAP_FAIL
    int ERROR_DEVICE_CLOSE_FAIL
    int ERROR_DEVICE_RESET_FAIL
    int ERROR_DEVICE_GETVERSION_FAIL
    int ERROR_DEVICE_VERSION_MISMATCH
    int ERROR_DEVICE_NOT_OPEN
    int ERROR_DEVICE_LOCKED
    int ERROR_INSTANCE_RUNNING
    int ERROR_INVALID_ARGUMENT
    int ERROR_INVALID_MODE
    int ERROR_INVALID_OPTION
    int ERROR_INVALID_MEMORY
    int ERROR_INVALID_RDATA
    int ERROR_NOT_INITIALIZED
    int ERROR_NOT_CALIBRATED
    int ERROR_DMA_FAIL
    int ERROR_XTDEVICE_FAIL
    int ERROR_FPGACONF_FAIL
    int ERROR_IFCONF_FAIL
    int ERROR_FIFORESET_FAIL
    int ERROR_STATUS_FAIL
    int ERROR_USB_GETDRIVERVER_FAIL
    int ERROR_USB_DRIVERVER_MISMATCH
    int ERROR_USB_GETIFINFO_FAIL
    int ERROR_USB_HISPEED_FAIL
    int ERROR_USB_VCMD_FAIL
    int ERROR_USB_BULKRD_FAIL
    int ERROR_HARDWARE_F01
    int ERROR_HARDWARE_F02
    int ERROR_HARDWARE_F03
    int ERROR_HARDWARE_F04
    int ERROR_HARDWARE_F05
    int ERROR_HARDWARE_F06
    int ERROR_HARDWARE_F07
    int ERROR_HARDWARE_F08
    int ERROR_HARDWARE_F09
    int ERROR_HARDWARE_F10
    int ERROR_HARDWARE_F11
    int ERROR_HARDWARE_F12
    int ERROR_HARDWARE_F13
    int ERROR_HARDWARE_F14
    int ERROR_HARDWARE_F15

class ErrorCodes:
    NONE = ERROR_NONE
    DEVICE_OPEN_FAIL = ERROR_DEVICE_OPEN_FAIL
    DEVICE_BUSY = ERROR_DEVICE_BUSY
    DEVICE_HEVENT_FAIL = ERROR_DEVICE_HEVENT_FAIL
    DEVICE_CALLBSET_FAIL = ERROR_DEVICE_CALLBSET_FAIL
    DEVICE_BARMAP_FAIL = ERROR_DEVICE_BARMAP_FAIL
    DEVICE_CLOSE_FAIL = ERROR_DEVICE_CLOSE_FAIL
    DEVICE_RESET_FAIL = ERROR_DEVICE_RESET_FAIL
    DEVICE_GETVERSION_FAIL = ERROR_DEVICE_GETVERSION_FAIL
    DEVICE_VERSION_MISMATCH = ERROR_DEVICE_VERSION_MISMATCH
    DEVICE_NOT_OPEN = ERROR_DEVICE_NOT_OPEN
    DEVICE_LOCKED = ERROR_DEVICE_LOCKED
    INSTANCE_RUNNING = ERROR_INSTANCE_RUNNING
    INVALID_ARGUMENT = ERROR_INVALID_ARGUMENT
    INVALID_MODE = ERROR_INVALID_MODE
    INVALID_OPTION = ERROR_INVALID_OPTION
    INVALID_MEMORY = ERROR_INVALID_MEMORY
    INVALID_RDATA = ERROR_INVALID_RDATA
    NOT_INITIALIZED = ERROR_NOT_INITIALIZED
    NOT_CALIBRATED = ERROR_NOT_CALIBRATED
    DMA_FAIL = ERROR_DMA_FAIL
    XTDEVICE_FAIL = ERROR_XTDEVICE_FAIL
    FPGACONF_FAIL = ERROR_FPGACONF_FAIL
    IFCONF_FAIL = ERROR_IFCONF_FAIL
    FIFORESET_FAIL = ERROR_FIFORESET_FAIL
    STATUS_FAIL = ERROR_STATUS_FAIL
    USB_GETDRIVERVER_FAIL = ERROR_USB_GETDRIVERVER_FAIL
    USB_DRIVERVER_MISMATCH = ERROR_USB_DRIVERVER_MISMATCH
    USB_GETIFINFO_FAIL = ERROR_USB_GETIFINFO_FAIL
    USB_HISPEED_FAIL = ERROR_USB_HISPEED_FAIL
    USB_VCMD_FAIL = ERROR_USB_VCMD_FAIL
    USB_BULKRD_FAIL = ERROR_USB_BULKRD_FAIL
    HARDWARE_F01 = ERROR_HARDWARE_F01
    HARDWARE_F02 = ERROR_HARDWARE_F02
    HARDWARE_F03 = ERROR_HARDWARE_F03
    HARDWARE_F04 = ERROR_HARDWARE_F04
    HARDWARE_F05 = ERROR_HARDWARE_F05
    HARDWARE_F06 = ERROR_HARDWARE_F06
    HARDWARE_F07 = ERROR_HARDWARE_F07
    HARDWARE_F08 = ERROR_HARDWARE_F08
    HARDWARE_F09 = ERROR_HARDWARE_F09
    HARDWARE_F10 = ERROR_HARDWARE_F10
    HARDWARE_F11 = ERROR_HARDWARE_F11
    HARDWARE_F12 = ERROR_HARDWARE_F12
    HARDWARE_F13 = ERROR_HARDWARE_F13
    HARDWARE_F14 = ERROR_HARDWARE_F14
    HARDWARE_F15 = ERROR_HARDWARE_F15

def __version__():
    '''Library version with 4 fields: 'a.b.c-d'
       Where the two first 'a' and 'b' comes from the manufacturer's library,
       the third is the build of this cypthon port and the last one is a 
       revision number.
    '''
    version = " "*10
    #three spaces will fit the size of the returning char*, but placed more
    # and cut it with the end string tag \x00.
    err = PH_GetLibraryVersion(version)
    if err == ERROR_NONE:
        return __strcut(version)+".%d-%d"%(BUILD_VERSION,REVISION_VERSION)
    else:
        raise Exception("cannot get the version")

cdef extern from "phlib.h":
    int PH_OpenDevice(int devidx, char* serial)
cdef extern from "phdefin.h":
    int MAXDEVNUM

class Discoverer(Logger):
    '''This class is to create a singleton object with the capacity to use the
       manufacturer's library to explore the computer seraching for 
       instruments.
    '''
    #TODO: in fact this is not a singleton, but it should.
    def __init__(self,debug=False):
        Logger.__init__(self, debug)
        self._name = "Discoverer"
        self._instruments = {}
        self.__getInstruments()

    def __getInstruments(self):
        '''Iterate between the possible IDs, looking for plugged instruments.
           If there is some, try to get the serial or in case of error, 
           interpret the returned error.
        '''
        sn = " "*10
        self.info("Searching for PicoHarp devices...")
        self.info("Devidx     Status")
        for i in range(MAXDEVNUM):
            err = PH_OpenDevice(i,sn)
            if err == ERROR_NONE:
                code = __strcut(sn)
                self.info("  %1d        S/N %s"%(i,code))
                self._instruments[code] = i
            elif err == ERROR_DEVICE_OPEN_FAIL:
                self.debug("  %1d        no device"%(i))
            else:
                #Errorstring = " "*40
                #PH_GetErrorString(Errorstring, err)
                self.error("  %1d        %s"%(i,self.interpretError(err)))
        return self

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
    int PH_GetBaseResolution(int devidx, double* resolution, int* binsteps)
    int PH_GetResolution(int devidx, double* resolution)
    int PH_GetCountRate(int devidx, int channel, int* rate)
    int PH_SetStopOverflow(int devidx, int stop_ovfl, int stopcount)
    int PH_ClearHistMem(int devidx, int block)
    int PH_StartMeas(int devidx, int tacq)
    int PH_StopMeas(int devidx)
    int PH_CTCStatus(int devidx, int* ctcstatus)
    int PH_GetHistogram(int devidx, unsigned int* chcount, int block)
    int PH_GetFlags(int devidx, int* flags)
    int PH_GetElapsedMeasTime(int devidx, double* elapsed)
    int PH_GetWarnings(int devidx, int* warnings)
    int PH_GetWarningsText(int devidx, char* text, int warnings)
    int PH_GetHardwareDebugInfo(int devidx, char *debuginfo)
cdef extern from "phdefin.h":
    int MODE_HIST
    #int MODE_T2
    #int MODE_T3
    int HISTCHAN
    int FLAG_OVERFLOW
    int SYNCDIVMIN
    int SYNCDIVMAX
    int ZCMIN
    int ZCMAX
    int DISCRMIN
    int DISCRMAX
    int BINSTEPSMAX
    int OFFSETMIN
    int OFFSETMAX
    int ACQTMIN
    int ACQTMAX
    int FLAG_FIFOFULL
    int FLAG_OVERFLOW
    int FLAG_SYSERROR

BLOCKMIN = 0
BLOCKMAX = 7

class Instrument(Logger):
    '''An object of this class represents an instrument. For such thing, it 
       could help to start using a discoverer to know, based on the serial 
       number, which is the current identifier for the instrument.
       The creation of this object can be used to configure the instrument, or
       it can be set up later using some getters that are available.
       
       Examples:
       >>> PicoHarp.Instrument(idx)
       >>> PicoHarp.Instrument(idx,debug=True)
       >>> PicoHarp.Instrument(idx,binning=0,acqTime=1000)
       >>> PicoHarp.Instrument(idx,binning=0,acqTime=1000,\
                               CFDLevels=[100,100],CFDZeroCross=[10,10])
       
       To close the connection with the instrument to free it, it's necessary
       to call the destructor.
    '''
    def __init__(self,devidx,mode=MODE_HIST,divider=1,binning=0,offset=0,
                 acqTime=1000,block=0,CFDLevels=[100,100],CFDZeroCross=[10,10],
                 stop=True,stopCount=HISTCHAN-1,debug=False):
        #super doesn't work!
        #super(Instrument,self).__init__(debug)
        try:
            Logger.__init__(self,debug)
            self._name = "Instrument%d"%devidx
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
            self._CFDLevel = CFDLevels
            self._CFDZeroCross = CFDZeroCross
            self._Binning = binning
            self._Offset = offset
            self._acquisitionTime = acqTime#ms
            self._block = block
            self._stop = stop
            self._stopCount = stopCount
            #readonly parameters
            self._Resolution = 0.0
            #outputs
            self._CountRate = [0,0]
            self._counts = [0]*HISTCHAN
            self._flags = 0
            self._integralCount = 0.0
            self.prepare()
            self._thread = None
            self._acqAbort = Event()
            self._acqAbort.clear()
        except Exception,e:
            self.error("Instrument.__init__() Exception: %s"%(e))
            raise e

    def prepare(self):
        '''This method is called in the object construction but is necessary 
           to be called again if the SyncDiv is changed.
        '''
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
        sleep(0.2)#200ms
        self.setStopOverflow()
        return self

    def acquire(self,async=False):
        '''Perform an acquisition in synchronous mode if it's not specified to
           be asynchronous.
           
           Examples:
           >>> instrument.acquire()           #synchronous acquisition
           >>> instrument.acquire(async=True) #asynchronous acquisition
        '''
        #TODO: check if this should be asynchronous to have the possibility to 
        #      see the histogram evolving during the acquisition.
        if self._thread != None and self._thread.isAlive():
            self.debug("Asynchronous acquisition in progress, please use "\
                       "isAsyncAcquisitionDone() to know when it's finished.")
            return False
        if not async:
            self.debug("Synchronous acquisition, return when finished")
            return self.__acquisitionProcedure()
        else:
            self.debug("Asynchronous acquisition, check "\
                       "isAsyncAcquisitionDone() to know it's finished")
            self._thread = Thread(target=self.__acquisitionProcedure,
                                  name="PicoHarpAcq")
            self._thread.start()
            return True

    def __acquisitionProcedure(self):
        '''This method does an acquisition bounded by the settings previously
           set up (or in the constructor on changed by the setters).
           
           The time that the instrument will be measuring is set by the 
           AcquisitionTime. The monitoring period inside this method will not
           disturb that time. The only effect is that this method will take 
           the exceed multiple of this time to return. The check is used to 
           know when an abort is received or if there has been triggered an
           error from the instrument. 
        '''
        try:
            self.info("Starting Acquisition procedure...")
            self.clearHistMem()
            self.getCountRates()
            self.startMeas()
            sleep(ACQ_MONITOR_T)
            waitloop = 0
            self._acqAbort.clear()
            while not self._acqAbort.isSet():
                waitloop += 1
                sleep(ACQ_MONITOR_T)
                #Periodically the acquisition has to wake up to check if there
                #has been an error (getCounterStatus will trigger an exception)
                #or it's still running (getCounterStatus return 0) or it has
                #ended (>0, usualy 1).
                if self.getCounterStatus()>0:
                    self.info("Acquisition completed")
                    break
            self.stopMeas()
            self.getHistogram()
            self.getFlags()
            self.integralCount()
            self.debug("waitloop = %d total count = %d"
                       %(waitloop,self._integralCount))
            if (self._flags&FLAG_OVERFLOW):
                self.debug("Overflow!")
                return False
            if self._acqAbort.isSet():
                self.debug("acquisition aborted!")
                return False
            return True
        except IOError,e:
            self.debug("I/O Error: %s"%(e))
            return False

    def isAsyncAcquisitionDone(self):
        '''When an acquisition has been launched in asynchronous mode, this 
           method with report if the acquisition has finished.
        '''
        if hasattr(self,'_thread') and self._thread != None:
            return not self._thread.isAlive()
        return True

    def abort(self):
        '''During an asynchronous acquisition, the way to stop a measurement 
           is call this method.
        '''
        if self._thread == None or not self._thread.isAlive():
            return False
        self._acqAbort.set()
        self.debug("Raised the abort flag!")
        return True

    def __del__(self):
        '''The destructor closes the connection with the instrument.
        '''
        err = PH_CloseDevice(self._devidx)
        if err != ERROR_NONE:
            raise IOError(err,"Close error (%d)"%(err))
        self.debug("Instrument connection closed.")

    def initialise(self):
        '''The instrument initialisation prepares the instrument for one of 
           the operation modes.
           But, by now this library only allows histogramming mode
           and T2 neither T3 are supported yet.
           If something went wrong an exception is raised with the code and 
           the meaning of this code.
        '''
        err = PH_Initialize(self._devidx,self._mode)
        if err != ERROR_NONE:
            raise IOError(err,"Init error (%d): %s"%(err,self.interpretError(err)))
        self.debug("Instrument initialised.")
        return self

    def __getHardwareInfo(self):
        '''Request to the indetified instrument some information about the 
           model it is, a partnum code and the firmware version it has. This 
           firmware version is independent to the library version.
        '''
        err = PH_GetHardwareInfo(self._devidx,self._HW_Model,
                                 self._HW_PartNo,self._HW_Version)
        if err != ERROR_NONE:
            raise IOError(err,"Getting hardware info error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Found Model %s Partnum %s Version %s"%(self._HW_Model,
                                                           self._HW_PartNo,
                                                           self._HW_Version))
        self._HW_Model = __strcut(self._HW_Model)
        self._HW_PartNo = __strcut(self._HW_PartNo)
        self._HW_Version = __strcut(self._HW_Version)
        return (self._HW_Model,self._HW_PartNo,self._HW_Version)

    def __calibrate(self):
        '''Command the instrument to proceed with it's calibration procedure.
        '''
        err = PH_Calibrate(self._devidx)
        if err != ERROR_NONE:
            raise IOError(err,"Calibration error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Instrument calibration done.")
        return self

    @property
    def __model__(self):
        return self._HW_Model

    @property
    def __partnum__(self):
        return self._HW_PartNo

    @property
    def __version__(self):
        return self._HW_Version

    @property
    def _SYNCDIVMIN(self):
        return SYNCDIVMIN
    @property
    def _SYNCDIVMAX(self):
        return SYNCDIVMAX

    def getSyncDivider(self):
        '''Get from the instrument the programmable divider in front of the 
           sync input. It's value must be with in SYNCDIVMIN and SYNCDIVMAX or,
           if it will not be used, set to 0 as the meaning of Null.
        '''
        return self._SyncDivider
    def setSyncDivider(self,syncDivider=None):
        '''Set to the instrument the value for the programmable divider in 
           front of the sync input. It's value must be with in SYNCDIVMIN 
           and SYNCDIVMAX or, if it will not be used, set to 0 as the 
           meaning of Null.
           
           Examples:
           >>> instrument.setSyncDivider()  #write to the hardware the value 
                                            #stored in the object.
           >>> instrument.setSyncDivider(0) #set the SyncDivider to not be used.
           >>> instrument.setSyncDivider(N) #set a value to the syncDivider.
        '''
        if syncDivider == None:
            syncDivider = self._SyncDivider
        if syncDivider != 0:
            if syncDivider < SYNCDIVMIN:
                raise ValueError("syncDivider must be above %d"%(SYNCDIVMIN))
            if syncDivider > SYNCDIVMAX:
                raise ValueError("syncDivider must be below %d"%(SYNCDIVMAX))
            err = PH_SetSyncDiv(self._devidx,syncDivider)
        else:
            err = PH_SetSyncDiv(self._devidx,0)
        if err != ERROR_NONE:
            raise IOError(err,"SetSyncDiv error (%d): %s"
                          %(err,self.interpretError(err)))
        self._SyncDivider = syncDivider
        self.debug("SetSyncDiv has been set (%d)"%(self._SyncDivider))
        return self
    
    @property
    def _DISCRMIN(self):
        return DISCRMIN
    @property
    def _DISCRMAX(self):
        return DISCRMAX
    @property
    def _ZCMIN(self):
        return ZCMIN
    @property
    def _ZCMAX(self):
        return ZCMAX
    
    def getInputCFD(self,channel):
        '''Each of the channels has its Constant Fraction Discriminator (CFD) 
           configurable, used to extract precise timing information from the 
           electrical detector pulses that may vary in amplitude.
           This method is returning a pair (zero cross,level) or the requested 
           channel where:
           - zero cross: allows to adapt to the noise from the given signal
           - level: the discriminator threshold that determines the lower limit
                    the detector pulse amplitude must pass.
           Unit: mV
        '''
        return (self._CFDZeroCross[channel],self._CFDLevel[channel])
    def setInputCFD(self,channel,CFDZeroCross=None,CFDLevel=None):
        '''Each of the channels has its Constant Fraction Discriminator (CFD) 
           configurable, used to extract precise timing information from the 
           electrical detector pulses that may vary in amplitude.
           This method is setting pair (zero cross,level) per channel where:
           - zero cross: allows to adapt to the noise from the given signal
           - level: the discriminator threshold that determines the lower limit
                    the detector pulse amplitude must pass.
           Unit: mV
           
           Examples:
           >>> instrument.setInputCFD(0) 
           #Set the pair stored in the object to the instrument for channel 0.
           >>> instrument.setInputCFD(1,CFDLevel=N) 
           #Set the discriminator level for channel 1. The zero cross will be
           #set to what is stored in the object.
           >>> instrument.setInputCFD(1,CFDLevel=N,CFDZeroCross=M)
           #Set both, level and zero cross for the specified channel 1.
        '''
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
            raise IOError(err,"setInputCFD error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("setInputCFD has been set for channel %d: "\
                   "(CFDLevel:%d,CFDZeroCross:%d)"
                   %(channel,CFDLevel,CFDZeroCross))
        self._CFDZeroCross[channel] = CFDZeroCross
        self._CFDLevel[channel] = CFDLevel
        return self

    @property
    def _BINSTEPSMAX(self):
        return BINSTEPSMAX

    def getBinning(self):
        '''The binning is used to modify the resolution (a read-only parameter)
           Its value can come from 0 to BINSTEPSMAX and it multiplies the
           base resolution of 4ps.
           
           Formula: resolution = baseResolution * (2^binning)
        '''
        return self._Binning
    def setBinning(self,Binning=None):
        '''The binning is used to modify the resolution (a read-only parameter)
           Its value can come from 0 to BINSTEPSMAX and it multiplies the
           base resolution of 4ps.
           
           Formula: resolution = baseResolution * (2^binning)
        '''
        if Binning == None:
            Binning = self._Binning
        err = PH_SetBinning(self._devidx,Binning)
        if err != ERROR_NONE:
            raise IOError(err,"SetBinning error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Binning = Binning
        self.debug("Binning = %d"%(self._Binning))
        return self
        
    @property
    def _OFFSETMIN(self):
        return OFFSETMIN
        
    def getOffset(self):
        '''With lower sync rates the region of interest of the histogram could 
           be lie outside the acquisition window. With this value is the time 
           shifted between the sync frame and the acquisition.
           With sync rates >5MHz this should be 0 always.
           Unit: ns
        '''
        return self._Offset
    def setOffset(self,Offset=None):
        '''With lower sync rates the region of interest of the histogram could 
           be lie outside the acquisition window. With this value is the time 
           shifted between the sync frame and the acquisition.
           With sync rates >5MHz this should be 0 always.
           Unit: ns
           
           Examples:
           >>> instrument.setOffset()  #write the stored value in the object
           >>> instrument.setOffset(N) #set it to the instrument and store it 
                                       #in the object.
        '''
        if Offset == None:
            Offset = self._Offset
        err = PH_SetOffset(self._devidx,Offset)
        if err != ERROR_NONE:
            raise IOError(err,"SetOffset error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Offset = Offset
        self.debug("Offset = %d"%(self._Offset))
        return self

    def getBaseResolution(self):
        '''The instrument has a resolution that can be adjusted using the 
           binning. But this method give the very basic value that will be
           the resolution without binning.
        '''
        cdef double baseResolution = 0.0
        cdef int binsteps = BINSTEPSMAX
        err = PH_GetBaseResolution(self._devidx,&baseResolution,&binsteps)
        if err != ERROR_NONE:
            raise IOError(err,"GetBaseResolution error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Base Resolution = %g"%(baseResolution))
        return baseResolution

    def getResolution(self):
        '''It represents the time per each of the points in the histogram. The 
           base resolution is 4ps and using the binning this can be set up by
           binary multiples (8,16,32,...,512ps)
        '''
        cdef double resolution = 0.0
        err = PH_GetResolution(self._devidx,&resolution)
        if err != ERROR_NONE:
            raise IOError(err,"GetResolution error (%d): %s"
                          %(err,self.interpretError(err)))
        self._Resolution = resolution
        self.debug("Resolution = %g"%(self._Resolution))
        return self._Resolution
    #There is no setter, use the binning.
    
    def getCountRate(self,channel):
        '''For a given channel get the number of counts received per second.
           It must be passed at least 100ms after initialise() or 
           setSyncDivider() to have a valid reading from this meter.
           Unit: Mcps (milions of counts per second)
        '''
        cdef int countrate = 0
        err = PH_GetCountRate(self._devidx,channel,&countrate)
        if err != ERROR_NONE:
            raise IOError(err,"GetCountRate channel %d error (%d): %s"
                          %(channel,err,self.interpretError(err)))
        self._CountRate[channel] = countrate
        self.debug("CountRate[%d] = %d"%(channel,self._CountRate[channel]))
        return countrate
    def getCountRates(self,channel=None):
        '''Get the pair of count rates on both channels.
           It must be passed at least 100ms after initialise() or 
           setSyncDivider() to have a valid reading from this meter.
           Unit: Mcps (milions of counts per second)
        '''
        if channel == None:
            channel = [0,1]
        elif channel in [0,1]:
            channel = [channel]
        else:
            raise IndexError("Channel not well specified.")
        for i in channel:
            self.getCountRate(i)
        return self._CountRate
    
    @property
    def _HISTCHAN(self):
        return HISTCHAN
    
    def getStopOverflow(self):
        '''The instrument acquisition can be configured to finish the 
           acquisition, even the acquisition time didn't finish, when any of 
           the channels reaches the maximum.
           This method returns a pair (stop,ct):
           - stop: boolean, if this feature is active or not
           - ct: integer defining this maximum to stop
        '''
        return (self._stop,self._stopCount)
    def setStopOverflow(self,stop=None,count=None):
        '''The instrument acquisition can be configured to finish the 
           acquisition, even the acquisition time didn't finish, when any of 
           the channels reaches the maximum.
           To configure this feature, there are two arguments:
           - stop: boolean, to set this feature is active or not
           - ct: integer defining this maximum to stop if it's active.
           
           Examples:
           >>> instrument.setStopOverflow()  #write the stored value in the
                                             #object
           >>> instrument.setStopOverflow(0) #disable this feature
           >>> instrument.setStopOverflow(1,HISTCHAN-1)
           #enable this feature, but put the roof to the maximum possible.
        '''
        if stop == None:
            stop = self._stop
        if count == None:
            count = self._stopCount
        else:
            if count < 1:
                raise ValueError("stop count must be above %d"%(1))
            elif count > HISTCHAN-1:
                raise ValueError("stop count must be below %d"%(HISTCHAN-1))
        err = PH_SetStopOverflow(self._devidx,stop,count)
        if err != ERROR_NONE:
            raise IOError(err,"SetStopOverflow error (%d): %s"
                          %(err,self.interpretError(err)))
        self._stop = stop
        self._stopCount = count
        self.debug("Overflow stopper set")
        return self

    @property
    def _BLOCKMIN(self):
        return BLOCKMIN
    @property
    def _BLOCKMAX(self):
        return BLOCKMAX

    def getBlock(self):
        '''Index of the memory block from the instrument, that will be used 
           for an acquisition or to get the histogram (in case it's not 
           specified precisely on any of those two calls).
        '''
        return self._block
    def setBlock(self,block):
        '''Set the instrument memory block to be used by default when start a 
           measurement or to get an histogram.
        '''
        self._block = block
        return self

    def clearHistMem(self,block=None):
        '''Clean old values in an instrument memory block
           
           Examples:
           >>> instrument.clearHistMem()  #set to 0s the default block 
                                          #histogram
           >>> instrument.clearHistMem(N) #set to 0s the specified block 
                                          #histogram
        '''
        if block == None:
            block = self._block
        err = PH_ClearHistMem(self._devidx,block)
        if err != ERROR_NONE:
            raise IOError(err,"ClearHistMem error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("Histogram memory (block %d) clean"%(block))
        return self

    @property
    def _ACQTMIN(self):
        return ACQTMIN
    @property
    def _ACQTMAX(self):
        return ACQTMAX

    def getAcquisitionTime(self):
        '''Lapse time during which the instrument will be accumulating counts
           Unit: ms
        '''
        return self._acquisitionTime
    def setAcquisitionTime(self,AcquisitionTime):
        '''Set up the time that the instrument will accumulate. An acquisition
           may take less if there is configured an stop overflow.
           Unit: ms
        '''
        if AcquisitionTime < ACQTMIN:
            raise ValueError("acq.time must be above %d"%(ACQTMIN))
        if AcquisitionTime > ACQTMAX:
            raise ValueError("acq.time must be below %d"%(ACQTMAX))
        self._acquisitionTime = AcquisitionTime
        return self

    def startMeas(self,AcquisitionTime=None):
        '''Call the instrument to start a measurement. Optionally this method 
           can receive an acquisition time that will overwrite the stored value.
        '''
        if AcquisitionTime == None:
            AcquisitionTime = self._acquisitionTime
        if AcquisitionTime < ACQTMIN:
            raise ValueError("acq.time must be above %d"%(ACQTMIN))
        if AcquisitionTime > ACQTMAX:
            raise ValueError("acq.time must be below %d"%(ACQTMAX))
        err = PH_StartMeas(self._devidx,AcquisitionTime)
        if err != ERROR_NONE:
            raise IOError(err,"StartMeas error (%d): %s"
                          %(err,self.interpretError(err)))
        self._acquisitionTime = AcquisitionTime
        self.debug("start measurement")
        return self
    
    def getCounterStatus(self):
        '''Check with the instrument if a measurement has finished the 
           acquisition.
           Return values:
           - 0:  acquisition still running
           - >0: acquisition has ended.
        '''
        cdef int ctcstatus=0
        err = PH_CTCStatus(self._devidx,&ctcstatus)
        if err < 0 and err != ERROR_NONE:
            raise IOError(err,"CTCStatus error (%d): %s"
                          %(err,self.interpretError(err)))
        #self.debug("counter status = %d"%(ctcstatus))
        return ctcstatus

    def stopMeas(self):
        '''Stops the current measurement.
           This must be called even if data collection has finished internally.
        '''
        err = PH_StopMeas(self._devidx)
        if err != ERROR_NONE:
            raise IOError(err,"StopMeas error (%d): %s"
                          %(err,self.interpretError(err)))
        self.debug("stop measurement")
        return self

    def getHistogram(self,block=None):
        '''Get a 1D array from the memory block by default or the specified 
           in the argument.
           
           Examples:
           >>> instrument.getHistogram()  #Get the histogram from the default 
                                          #block
           >>> instrument.getHistogram(N) #Get the histogram from the 
                                          #specified block
        '''
        if block == None:
            block = self._block
        #cdef np.ndarray[np.uint32_t, ndim=1] counts = np.zeros([HISTCHAN],
        #                                                     dtype=np.uint32)
        cdef unsigned int *counts
        try:
            #counts = <unsigned int*>malloc(HISTCHAN*cython.sizeof(int))
            #counts = <unsigned int*>calloc(HISTCHAN,cython.sizeof(int))
            counts = <unsigned int*>PyMem_Malloc(HISTCHAN*cython.sizeof(int))
            if not counts:
                self.debug("Exception in histogram malloc")
                return [None]*HISTCHAN
        except Exception,e:
            self.debug("Exception in histogram malloc: %s"%(e))
            return [None]*HISTCHAN
        err = PH_GetHistogram(self._devidx,counts,block)
        if err != ERROR_NONE:
            raise IOError(err,"GetHistogram error (%d): %s"
                          %(err,self.interpretError(err)))
        for i in xrange(len(self._counts)):
            self._counts[i] = counts[i]
        PyMem_Free(counts)
        if len(self._counts)>21:
            self.debug("Histogram (block %d): %s (...) %s"
                       %(block,repr(self._counts[:7])[:-1],
                         repr(self._counts[-7:])[1:]))
        else:
            self.debug("Histogram (block %d): %s"%(block,self._counts))
        return self._counts

    @property
    def _FLAG_FIFOFULL(self):
        return FLAG_FIFOFULL
    @property
    def _FLAG_OVERFLOW(self):
        return FLAG_OVERFLOW
    @property
    def _FLAG_SYSERROR(self):
        return FLAG_SYSERROR

    def getFlags(self):
        '''Returns a integer with the bit array flags.
           FLAG_FIFOFULL     0x0003  //T-modes
           FLAG_OVERFLOW     0x0040  //Histomode
           FLAG_SYSERROR     0x0100  //Hardware problem
        '''
        cdef int flags = 0
        err = PH_GetFlags(self._devidx,&flags)
        if err != ERROR_NONE:
            raise IOError(err,"GetFlags error (%d): %s"
                          %(err,self.interpretError(err)))
        self._flags = flags
        self.debug("Flags: %s"%(bin(self._flags)))
        return self._flags

    def integralCount(self):
        '''After get an histogram, calculate the accumulated counts in the 
           array.
        '''
        integralCount = 0
        for count in self._counts:
            integralCount += count
        self._integralCount = integralCount
        self.debug("Integral count = %d"%(self._integralCount))
        return self._integralCount
    
    def getElapsedMeasTime(self):
        cdef double elapsed
        err = PH_GetElapsedMeasTime(self._devidx,&elapsed)
        if err != ERROR_NONE:
            raise IOError(err,"getElapsedMeasTime error (%d): %s"
                          %(err,self.interpretError(err)))
        return elapsed
    
    def getWarnings(self):
        self.getCountRates()#this must be called before getWarninings
        cdef int warnings
        err = PH_GetWarnings(self._devidx,&warnings)
        if err != ERROR_NONE:
            raise IOError(err,"getWarnings error (%d): %s"
                          %(err,self.interpretError(err)))
        return warnings
    def getWarningsText(self,warnings=None):
        if warnings == None:
            warnings = self.getWarnings()
        text = " "*16384
        err = PH_GetWarningsText(self._devidx,text,warnings)
        if err != ERROR_NONE:
            raise IOError(err,"getWarnings error for warning %d (%d): %s"
                          %(warnings,err,self.interpretError(err)))
        return __strcut(text)
    def getHardwareDebugInfo(self):
        debuginfo = " "*16384
        err = PH_GetHardwareDebugInfo(self._devidx,debuginfo)
        if err != ERROR_NONE:
            raise IOError(err,"getHardwareDebugInfo error (%d): %s"
                          %(err,self.interpretError(err)))
        return __strcut(debuginfo)

class InstrumentSimulator(Logger):
    '''A pure python class that overloads the methods from the real instrument
      made to allow practical with fake data when no instrument is available.
    '''
    def __init__(self,mode=MODE_HIST,divider=1,binning=0,offset=0,
                 acqTime=1000,block=0,CFDLevels=[100,100],CFDZeroCross=[10,10],
                 stop=True,stopCount=HISTCHAN-1,debug=False):
        try:
            deviceId = None
            #super doesn't work
#            super(Logger,self).__init__(debug)
            Logger.__init__(self,debug)
            self._name = "InstrumentSimulator"
            if mode != MODE_HIST:
                raise NotImplementedError("Only histogram mode supported")
            self._mode = mode
            self.initialise()
            self._HW_Model = 'Simulator'
            self._HW_PartNo = '000000'
            self._HW_Version = '0.1'
            self.__getHardwareInfo()
            self.__calibrate()
            #configurable parameters
            self._SyncDivider = divider
            self._CFDLevel = CFDLevels
            self._CFDZeroCross = CFDZeroCross
            self._Binning = binning
            self._Offset = offset
            self._acquisitionTime = acqTime#ms
            self._startMeasTime = None
            self._block = block
            self._stop = stop
            self._stopCount = stopCount
            #readonly parameters
            self._Resolution = 0.0
            self._BaseResolution = 4.0#ps
            #Simulation parameters
            self.distribution('uniform')
            self._groups = 10
            #outputs
            self._CountRate = [0,0]
            self._counts = [0]*HISTCHAN
            self._histograms = [[0L]*HISTCHAN]*8
            self._flags = 0
            self._integralCount = 0.0
            self.prepare()
            self._thread = None
            self._acqAbort = Event()
            self._acqAbort.clear()
        except Exception,e:
            self.error("InstrumentSimulator.__init__() Exception: %s"%(e))
            raise e

    def prepare(self):
        '''This method is called in the object construction but is necessary 
           to be called again if the SyncDiv is changed.
        '''
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
        sleep(0.2)#200ms
        self.setStopOverflow()
        return self

    def acquire(self,async=False):
        '''Perform an acquisition in synchronous mode if it's not specified to
           be asynchronous.
           
           Examples:
           >>> instrument.acquire()           #synchronous acquisition
           >>> instrument.acquire(async=True) #asynchronous acquisition
        '''
        #TODO: check if this should be asynchronous to have the possibility to 
        #      see the histogram evolving during the acquisition.
        if self._thread != None and self._thread.isAlive():
            self.debug("Asynchronous acquisition in progress, please use "\
                       "isAsyncAcquisitionDone() to know when it's finished.")
            return False
        if not async:
            self.debug("Synchronous acquisition, return when finished")
            return self.__acquisitionProcedure()
        else:
            self.debug("Asynchronous acquisition, check "\
                       "isAsyncAcquisitionDone() to know it's finished")
            self._thread = Thread(target=self.__acquisitionProcedure,
                                  name="PicoHarpAcq")
            self._thread.start()
            return True

    def __acquisitionProcedure(self):
        '''This method does an acquisition bounded by the settings previously
           set up (or in the constructor on changed by the setters).
           
           The time that the instrument will be measuring is set by the 
           AcquisitionTime. The monitoring period inside this method will not
           disturb that time. The only effect is that this method will take 
           the exceed multiple of this time to return. The check is used to 
           know when an abort is received or if there has been triggered an
           error from the instrument. 
        '''
        try:
            self.info("Starting Acquisition procedure...")
            self.clearHistMem()
            self.getCountRates()
            self.startMeas()
            sleep(ACQ_MONITOR_T)
            waitloop = 0
            self._acqAbort.clear()
            while not self._acqAbort.isSet():
                waitloop += 1
                sleep(ACQ_MONITOR_T)
                #Periodically the acquisition has to wake up to check if there
                #has been an error (getCounterStatus will trigger an exception)
                #or it's still running (getCounterStatus return 0) or it has
                #ended (>0, usualy 1).
                if self.getCounterStatus()>0:
                    self.info("Acquisition completed")
                    break
            self.stopMeas()
            self.getHistogram()
            self.getFlags()
            self.integralCount()
            self.debug("waitloop = %d total count = %d"
                       %(waitloop,self._integralCount))
            if (self._flags&FLAG_OVERFLOW):
                self.debug("Overflow!")
                return False
            if self._acqAbort.isSet():
                self.debug("acquisition aborted!")
                return False
            return True
        except IOError,e:
            self.debug("I/O Error: %s"%(e))
            return False

    def isAsyncAcquisitionDone(self):
        '''When an acquisition has been launched in asynchronous mode, this 
           method with report if the acquisition has finished.
        '''
        if hasattr(self,'_thread') and self._thread != None:
            return not self._thread.isAlive()
        return True

    def abort(self):
        '''During an asynchronous acquisition, the way to stop a measurement 
           is call this method.
        '''
        if self._thread == None or not self._thread.isAlive():
            return False
        self._acqAbort.set()
        self.debug("Raised the abort flag!")
        return True

    @property
    def __model__(self):
        return self._HW_Model

    @property
    def __partnum__(self):
        return self._HW_PartNo

    @property
    def __version__(self):
        return self._HW_Version

    def integralCount(self):
        '''After get an histogram, calculate the accumulated counts in the 
           array.
        '''
        integralCount = 0
        for count in self._counts:
            integralCount += count
        self._integralCount = integralCount
        self.debug("Integral count = %d"%(self._integralCount))
        return self._integralCount

    def __del__(self):
        '''The destructor closes the connection with the instrument.
        '''
        try:
            if hasattr(self,'__debug'):
                self.debug("Instrument connection closed.")
        except Exception,e:
            self.error("InstrumentSimulator.__del__() Exception: %s"%(e))

    def initialise(self):
        '''The instrument initialisation prepares the instrument for one of 
           the operation modes.
           But, by now this library only allows histogramming mode
           and T2 neither T3 are supported yet.
           If something went wrong an exception is raised with the code and 
           the meaning of this code.
        '''
        return self

    def __getHardwareInfo(self):
        '''Request to the indetified instrument some information about the 
           model it is, a partnum code and the firmware version it has. This 
           firmware version is independent to the library version.
        '''
        return (self._HW_Model,self._HW_PartNo,self._HW_Version)

    def __calibrate(self):
        '''Command the instrument to proceed with it's calibration procedure.
        '''
        self.debug("Instrument calibration done.")
        return self

    def getSyncDivider(self):
        '''Get from the instrument the programmable divider in front of the 
           sync input. It's value must be with in SYNCDIVMIN and SYNCDIVMAX or,
           if it will not be used, set to 0 as the meaning of Null.
        '''
        return self._SyncDivider

    def setSyncDivider(self,syncDivider=None):
        '''Set to the instrument the value for the programmable divider in 
           front of the sync input. It's value must be with in SYNCDIVMIN 
           and SYNCDIVMAX or, if it will not be used, set to 0 as the 
           meaning of Null.
           
           Examples:
           >>> instrument.setSyncDivider()  #write to the hardware the value 
                                            #stored in the object.
           >>> instrument.setSyncDivider(0) #set the SyncDivider to not be used.
           >>> instrument.setSyncDivider(N) #set a value to the syncDivider.
        '''
        if syncDivider == None:
            syncDivider = self._SyncDivider
        if syncDivider != 0:
            if syncDivider < SYNCDIVMIN:
                raise ValueError("syncDivider must be above %d"%(SYNCDIVMIN))
            if syncDivider > SYNCDIVMAX:
                raise ValueError("syncDivider must be below %d"%(SYNCDIVMAX))
        self._SyncDivider = syncDivider
        self.debug("SetSyncDiv has been set (%d)"%(self._SyncDivider))
        return self

    def getInputCFD(self,channel):
        '''Each of the channels has its Constant Fraction Discriminator (CFD) 
           configurable, used to extract precise timing information from the 
           electrical detector pulses that may vary in amplitude.
           This method is returning a pair (zero cross,level) or the requested 
           channel where:
           - zero cross: allows to adapt to the noise from the given signal
           - level: the discriminator threshold that determines the lower limit
                    the detector pulse amplitude must pass.
           Unit: mV
        '''
        return (self._CFDZeroCross[channel],self._CFDLevel[channel])

    def setInputCFD(self,channel,CFDZeroCross=None,CFDLevel=None):
        '''Each of the channels has its Constant Fraction Discriminator (CFD) 
           configurable, used to extract precise timing information from the 
           electrical detector pulses that may vary in amplitude.
           This method is setting pair (zero cross,level) per channel where:
           - zero cross: allows to adapt to the noise from the given signal
           - level: the discriminator threshold that determines the lower limit
                    the detector pulse amplitude must pass.
           Unit: mV
           
           Examples:
           >>> instrument.setInputCFD(0) 
           #Set the pair stored in the object to the instrument for channel 0.
           >>> instrument.setInputCFD(1,CFDLevel=N) 
           #Set the discriminator level for channel 1. The zero cross will be
           #set to what is stored in the object.
           >>> instrument.setInputCFD(1,CFDLevel=N,CFDZeroCross=M)
           #Set both, level and zero cross for the specified channel 1.
        '''
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
        self.debug("setInputCFD has been set for channel %d: "\
                   "(CFDLevel:%d,CFDZeroCross:%d)"
                   %(channel,CFDLevel,CFDZeroCross))
        self._CFDZeroCross[channel] = CFDZeroCross
        self._CFDLevel[channel] = CFDLevel
        return self

    def getBinning(self):
        '''The binning is used to modify the resolution (a read-only parameter)
           Its value can come from 0 to BINSTEPSMAX and it multiplies the
           base resolution of 4ps.
           
           Formula: resolution = baseResolution * (2^binning)
        '''
        return self._Binning

    def setBinning(self,Binning=None):
        '''The binning is used to modify the resolution (a read-only parameter)
           Its value can come from 0 to BINSTEPSMAX and it multiplies the
           base resolution of 4ps.
           
           Formula: resolution = baseResolution * (2^binning)
        '''
        if Binning == None:
            Binning = self._Binning
        self._Resolution = self._BaseResolution * (2 ** Binning)
        self._Binning = Binning
        self.debug("Binning = %d (Resolution = %g)"
                   %(self._Binning,self._Resolution))
        return self

    def getOffset(self):
        '''With lower sync rates the region of interest of the histogram could 
           be lie outside the acquisition window. With this value is the time 
           shifted between the sync frame and the acquisition.
           With sync rates >5MHz this should be 0 always.
           Unit: ns
        '''
        return self._Offset

    def setOffset(self,Offset=None):
        '''With lower sync rates the region of interest of the histogram could 
           be lie outside the acquisition window. With this value is the time 
           shifted between the sync frame and the acquisition.
           With sync rates >5MHz this should be 0 always.
           Unit: ns
           
           Examples:
           >>> instrument.setOffset()  #write the stored value in the object
           >>> instrument.setOffset(N) #set it to the instrument and store it 
                                       #in the object.
        '''
        if Offset == None:
            Offset = self._Offset
        self._Offset = Offset
        self.debug("Offset = %d"%(self._Offset))
        return self

    def getBaseResolution(self):
        '''The instrument has a resolution that can be adjusted using the 
           binning. But this method give the very basic value that will be
           the resolution without binning.
        '''
        self.debug("BaseResolution = %g"%(self._BaseResolution))
        return self._BaseResolution

    def getResolution(self):
        '''It represents the time per each of the points in the histogram. The 
           base resolution is 4ps and using the binning this can be set up by
           binary multiples (8,16,32,...,512ps)
        '''
        self.debug("Resolution = %g"%(self._Resolution))
        return self._Resolution
    #There is no setter, use the binning.

    def getCountRate(self,channel):
        '''For a given channel get the number of counts received per second.
           It must be passed at least 100ms after initialise() or 
           setSyncDivider() to have a valid reading from this meter.
           Unit: Mcps (milions of counts per second)
        '''
        self._CountRate[channel] = random.randint(9e5,1e6)
        self.debug("CountRate[%d] = %d"%(channel,self._CountRate[channel]))
        return self._CountRate[channel]

    def getCountRates(self,channel=None):
        '''Get the pair of count rates on both channels.
           It must be passed at least 100ms after initialise() or 
           setSyncDivider() to have a valid reading from this meter.
           Unit: Mcps (milions of counts per second)
        '''
        if channel == None:
            channel = [0,1]
        elif channel in [0,1]:
            channel = [channel]
        else:
            raise IndexError("Channel not well specified.")
        for i in channel:
            self.getCountRate(i)
        return self._CountRate

    def getStopOverflow(self):
        '''The instrument acquisition can be configured to finish the 
           acquisition, even the acquisition time didn't finish, when any of 
           the channels reaches the maximum.
           This method returns a pair (stop,ct):
           - stop: boolean, if this feature is active or not
           - ct: integer defining this maximum to stop
        '''
        return (self._stop,self._stopCount)

    def setStopOverflow(self,stop=None,count=None):
        '''The instrument acquisition can be configured to finish the 
           acquisition, even the acquisition time didn't finish, when any of 
           the channels reaches the maximum.
           To configure this feature, there are two arguments:
           - stop: boolean, to set this feature is active or not
           - ct: integer defining this maximum to stop if it's active.
           
           Examples:
           >>> instrument.setStopOverflow()  #write the stored value in the 
                                             #object
           >>> instrument.setStopOverflow(0) #disable this feature
           >>> instrument.setStopOverflow(1,HISTCHAN-1)
           #enable this feature, but put the roof to the maximum possible.
        '''
        if stop == None:
            stop = self._stop
        if count == None:
            count = self._stopCount
        else:
            if count < 1:
                raise ValueError("stop count must be above %d"%(1))
            elif count > HISTCHAN-1:
                raise ValueError("stop count must be below %d"%(HISTCHAN-1))
        self._stop = stop
        self._stopCount = count
        self.debug("Overflow stopper set")
        return self

    def getBlock(self):
        '''Index of the memory block from the instrument, that will be used 
           for an acquisition or to get the histogram (in case it's not 
           specified precisely on any of those two calls).
        '''
        return self._block

    def setBlock(self,block):
        '''Set the instrument memory block to be used by default when start a 
           measurement or to get an histogram.
        '''
        self._block = block
        return self

    def clearHistMem(self,block=None):
        '''Clean old values in an instrument memory block
           
           Examples:
           >>> instrument.clearHistMem()  #set to 0s the default block 
                                          #histogram
           >>> instrument.clearHistMem(N) #set to 0s the specified block 
                                          #histogram
        '''
        if block == None:
            block = self._block
        self._histograms[block] = [0L]*HISTCHAN
        self.debug("Histogram memory (block %d) clean"%(block))
        return self

    def getAcquisitionTime(self):
        '''Lapse time during which the instrument will be accumulating counts
           Unit: ms
        '''
        return self._acquisitionTime

    def setAcquisitionTime(self,AcquisitionTime):
        '''Set up the time that the instrument will accumulate. An acquisition
           may take less if there is configured an stop overflow.
           Unit: ms
        '''
        if AcquisitionTime < ACQTMIN:
            raise ValueError("acq.time must be above %d (%d)"%(ACQTMIN,AcquisitionTime))
        if AcquisitionTime > ACQTMAX:
            raise ValueError("acq.time must be below %d"%(ACQTMAX))
        self._acquisitionTime = AcquisitionTime
        return self

    def startMeas(self,AcquisitionTime=None):
        '''Call the instrument to start a measurement. Optionally this method 
           can receive an acquisition time that will overwrite the stored 
           value.
        '''
        if AcquisitionTime == None:
            AcquisitionTime = self._acquisitionTime
        if AcquisitionTime < ACQTMIN:
            raise ValueError("acq.time must be above %d"%(ACQTMIN))
        if AcquisitionTime > ACQTMAX:
            raise ValueError("acq.time must be below %d"%(ACQTMAX))
        self._acquisitionTime = AcquisitionTime
        self._startMeasTime = datetime.now()
        self.debug("start measurement (%s)"%(self._startMeasTime))
        return self
    
    def getCounterStatus(self):
        '''Check with the instrument if a measurement has finished the 
           acquisition.
           Return values:
           - 0:  acquisition still running
           - >0: acquisition has ended.
        '''
        self.info("elapsed: %g (acq: %g)"
                  %(self.getElapsedMeasTime(),self._acquisitionTime))
        if self.getElapsedMeasTime() >= self._acquisitionTime:
            self.getHistogram()
            return 1
        else:
            #counts to add
            counts2add = random.randint(1e6,1e9)
            self.debug("Add %d counts"%(counts2add))
            while counts2add > 0:
                pos = self.getRandomPosition()
                try:
                    if self._histograms[self._block][pos] < HISTCHAN:
                        self._histograms[self._block][pos] += 1
                        counts2add -= 1
                except Exception,e:
                    self.error("Ups, this shouldn't happen in "\
                               "getCounterStatus: %s"%(e))
                    self.debug("Position = %d (max %d)"%(pos,HISTCHAN))
            #self.getHistogram()
            return 0

    def distribution(self,value=None):
        #cython doesn't support decorator @property.setter
        if value == None:
            return self._distribution
        elif value in ['uniform','gaussian']:
            self._distribution = value

    def groups(self,value=None):
        if value == None:
            return self._groups
        else:
            self._groups = value

    def getRandomPosition(self):
        try:
            groupSize = HISTCHAN/self.groups()
            empty = groupSize/10
            group = int(random.uniform(0,self.groups()))
            pos = -1
            while not (0 <=  pos <= HISTCHAN-1):
                section = group*groupSize
                if self.distribution() == 'uniform':
                    start = section+empty
                    end = section+groupSize-empty
                    pos = random.randrange(start,end,2)
                elif self.distribution() == 'gaussian':
                    mu = section+(groupSize/2)
                    sigma = groupSize/self.groups()
                    pos = int(random.gauss(mu,sigma))
                    if not pos % 2:
                        pos += 1
            return pos
        except Exception,e:
            self.error("no random possition in %s: %s"%(self.distribution(),e))
            return 1

    def stopMeas(self):
        '''Stops the current measurement.
           This must be called even if data collection has finished internally.
        '''
        self.debug("stop measurement")
        self._startMeasTime = None
        return self

    def getHistogram(self,block=None):
        '''Get a 1D array from the memory block by default or the specified 
           in the argument.
           
           Examples:
           >>> instrument.getHistogram()  #Get the histogram from the 
                                          #default block
           >>> instrument.getHistogram(N) #Get the histogram from the 
                                          #specified block
        '''
        if block == None:
            block = self._block
        self._counts = self._histograms[block]
        if len(self._counts)>21:
            #Debug string, but cut the data when it's too long
            self.debug("Histogram (block %d): %s (...) %s"
                       %(block,repr(self._counts[:7])[:-1],
                         repr(self._counts[-7:])[1:]))
        else:
            self.debug("Histogram (block %d): %s"%(block,self._counts))
        return self._counts

    def getFlags(self):
        '''Returns a integer with the bit array flags.
           FLAG_FIFOFULL     0x0003  //T-modes
           FLAG_OVERFLOW     0x0040  //Histomode
           FLAG_SYSERROR     0x0100  //Hardware problem
        '''
        self._flags = 176
        self.debug("Flags: %s"%(bin(self._flags)))
        return self._flags

    def getElapsedMeasTime(self):
        '''Get the time acquiring in miliseconds. 0 in other case, like not 
           currently acquiring.
        '''
        if not self._startMeasTime == None:
            #self.warning("now %s and start %s"
            #             %(datetime.now(),self._startMeasTime))
            t_diff = datetime.now() - self._startMeasTime
            if hasattr(t_diff,'total_seconds'):
                elapsed = t_diff.total_seconds()*1e3
            else:
                elapsed = t_diff.seconds*1e3
            self.debug("Measuring since %s"%(elapsed))
            return elapsed
        else:
            return 0

    def getWarnings(self):
        self.getCountRates()#this must be called before getWarninings
        return 17

    def getWarningsText(self,warnings=None):
        return ""

    def getHardwareDebugInfo(self):
        return "FPGA mode:      0\n"\
               "Device state:     3\n"\
               "Sync Divider:     %d\n"\
               "Binning:            %d\n"\
               "Current Flags = 0x00a4\n"\
               "Current ErrFlags = 0x0000"%(self._SyncDivider,self._Binning)
