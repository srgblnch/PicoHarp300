###############################################################################
## file :               collectPhCt.py
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

import time
LISTMAXDUMP = 10

class Logger:
    '''This is a superclass to manage the logging feature.
    '''
    error   = 1
    warning = 2
    info    = 3
    debug   = 4
    trace   = 5
    
    def loglevels(self):
        '''Get the dictionary with string level meanings as keys and 
           codes as items.
        '''
        return {"error":Logger.error,"warning":Logger.warning,
                "info":Logger.info,
                "debug":Logger.debug,"trace":Logger.trace}
    def logString2Code(self,string):
        '''Given a string level meaning, get the corresponding code.
        '''
        try:
            return self.loglevels()[string.lower()]
        except:
            self.error_stream("Not recognized log level '%s', "\
                              "using default 'info' level."%(string))
            return None
    def logCode2String(self,value):
        '''Given a log level code, get the corresponding string meaning.
        '''
        if value in self.loglevels().values():
            for string,code in self.loglevels().items():
                if value == code:
                    return string
        else:
            self.error_stream("Not recognized log level code '%s'."%(value))
            return "----"
    def __init__(self,loglevel):
        self._loglevel = None
        self.setLogLevel(loglevel)
    def getLogLevel(self):
        return self._loglevel
    def setLogLevel(self,loglevel):
        if type(loglevel) == int and 1 <= loglevel <= 5:
            self._loglevel = loglevel
        elif type(loglevel) == str:
            self._loglevel = self.logString2Code(loglevel)
        else:
            self.error_stream("Not recognized log level '%s', "\
                              "using default 'info' level."%(loglevel))
            self._loglevel = Logger.info
    
    #----# first level
    def error_stream(self,logtext,data=None):
        '''Stream to report errors to the command line output.
        '''
        self._print_stream(logtext,Logger.error,data)

    def warning_stream(self,logtext,data=None):
        '''Stream to report warnings to the command line output. Can be 
           silenced if the level set is error.
        '''
        self._print_stream(logtext,Logger.warning,data)

    def info_stream(self,logtext,data=None):
        '''Stream to report information to the command line output. Can be 
           silenced if the level set is warning or below.
        '''
        self._print_stream(logtext,Logger.info,data)

    def debug_stream(self,logtext,data=None):
        '''Stream to report debug to the command line output. Can be 
           silenced if the level set is info or below.
        '''
        self._print_stream(logtext,Logger.debug,data)

    def trace_stream(self,logtext,data=None):
        '''Stream to report trace to the command line output. Can be 
           silenced if the level set is debug or below.
        '''
        self._print_stream(logtext,Logger.trace,data)

    #----# second level
    def _print_stream(self,logtext,loglevel,data=None):
        '''Internal method to be used by the available streams.
        '''
        if self._loglevel >= loglevel:
            self._print_line(logtext,loglevel,data)
    def _print_line(self,logtext,loglevel,data=None):
        '''Internal method to build a line to be printed
        '''
        msg="%s\t%s\t"%(self.logCode2String(loglevel).upper(),logtext)
        if not data==None:
            msg += self._print_data(data)
        print msg

    #----# Third level
    def _isInteger(self,data):
        '''Internal method to check integer types
        '''
        return type(data) in [int,long]
    def _isFloat(self,data):
        '''Internal method to check float types
        '''
        return type(data) in [float]
    def _isList(self,data):
        '''Internal method to check list types
        '''
        return type(data)==list
    def _print_data(self,data):
        '''Internal method to print the data field.
        '''
        if self._isInteger(data):
            return self._printInteger(data)
        elif self._isFloat(data):
            return self._printFloat(data)
        elif self._isList(data):
            return self._printList(data)
        else:
            return " %s "%(data)
    def _printInteger(self,data):
        '''Internal method to print integers.
        '''
        return " %s "%(data)
    def _printFloat(self,data):
        '''Internal method to print floats.
        '''
        return " %g "%(data)
    def _printList(self,data):
        '''Internal method to print lists. This, as a logging system, will not
           print all the elements in the list. They will be represented by
           some from the beginning and some from the end.
        '''
        if len(data) <= LISTMAXDUMP:
            return "%s"%data
        msg = " [ "
        i = 0
        while i <= LISTMAXDUMP/2:
            msg += self._print_data(data[i])
            i += 1
        msg += " (...) "
        i = LISTMAXDUMP/2
        while i > 0:
            msg += self._print_data(data[-i])
            i += 1
        msg += " ] "
        return msg
#----# end class Logger

import PyTango
from threading import Event

MAXOUTPUTSIZE = 2.0
MAXOUTPUTUNIT = "GB"

class Collector(Logger):
    '''Main class here. Made to, knowing the device and the attribute from 
       where the data wants to be collected, manage the events to store in a
       file.
    '''
    def __init__(self,devName,attrName,timecollecting,output,
                 loglevel=Logger.info):
        Logger.__init__(self, loglevel)
        self.trace_stream("Collector.__init__()")
        self._devName = devName
        self._dproxy = PyTango.DeviceProxy(self._devName)
        self._attrName = attrName
        self._tcollecting = timecollecting
        self._outputName = output
        self._ctrlC = Event()
        self._ctrlC.clear()
        self._events = []
        self._csv = CSVOutput(self._outputName,
                              "%s/%s"%(self._devName,self._attrName),
                              self.getLogLevel())
    #----# first level
    def start(self):
        '''Start the procedure to collect information from where the object
           is configured and store it where the object is also configured to.
        '''
        self.trace_stream("Collector.start()")
        self.subscribe()
        self._csv.open()
        self._csv.writeHeader()
        start_t = time.time()
        while not self._ctrlC.isSet():
            seconds = int(time.time() - start_t)
            if seconds % 10 == 0 and seconds >= 10 and self._checkFileTooBig():
                break
            if seconds % 60 == 0 and seconds >= 60 and \
                                            self._checkTimeCollecting(seconds):
                break
            time.sleep(1)
        self.unsubscribe()
        self._csv.close()
    def stop(self):
        '''Procedure to stop a data collection.
        '''
        self.trace_stream("Collector.stop()")
        self._ctrlC.set()
        self.info_stream("Wait the stop process to finish...")
    #----# second level
    def subscribe(self):
        '''Method to do the procedure to subscribe to all the events this 
           object needs.
        '''
        self.trace_stream("Collector.subscribe()")
        try:
            eventId = self._dproxy.subscribe_event(self._attrName,
                                                PyTango.EventType.CHANGE_EVENT,
                                                self._histogramChangeEvent)
            self._events.append(eventId)
        except Exception,e:
            self.error_stream("cannot subscribe",e)
    def unsubscribe(self):
        '''Process to unsubscribe all the events managed by this object.
        '''
        self.trace_stream("Collector.unsubscribe()")
        for eventId in self._events:
            self.debug_stream("unsubscribe id",eventId)
            self._dproxy.unsubscribe_event(eventId)
    def _histogramChangeEvent(self,event):
        '''Callback method for the histogram events.
        '''
        self.trace_stream("Collector._histogramChangeEvent()")
        if event == None or \
                    (hasattr(event,"attr_value") and event.attr_value == None):
            self.warning_stream("Null event received",event)
            return
        try:
            tstamp = "%s.%s"\
                     %(event.attr_value.time.tv_sec,
                       event.attr_value.time.tv_usec)
            quality = "%s"%(event.attr_value.quality)
            self.debug_stream("%s/%s\t%s\t%s"
                              %(self._devName,self._attrName,tstamp,quality),
                              event.attr_value.value)
            self._csv.writeEvent(event)
        except Exception,e:
            self.error_stream("event exception",e)
    #----# third level
    def _checkFileTooBig(self):
        fileSize,unit = self._csv.getSize()
        if unit == MAXOUTPUTUNIT and fileSize >= MAXOUTPUTSIZE:
            self.error_stream("Reached the maximum output file "\
                              "allowed (%s %s). Force finish!"
                              %(MAXOUTPUTSIZE,MAXOUTPUTUNIT))
            return True
        return False
    def _checkTimeCollecting(self,period):
        minutes = seconds / 60
        fileSize,unit = self._csv.getSize()
        msg = "%d minute(s) collecting (file size %s %s)"\
              %(minutes,fileSize,unit)
        if not unit == MAXOUTPUTUNIT:
            self.info_stream(msg)
        else:
            self.warning_stream("%s: be careful with the output "\
                                "file size!"%(msg))
        if minutes >= self._tcollecting:
            self.info_stream("Time collecting completed (%d). "\
                             "Finishing"%(self._tcollecting))
            return True
        return False
#----# end class Collector

from numpy import ndarray
import os
import math

class CSVOutput(Logger):
    '''Class to handle the output file of the collector object. In particular 
       this class will output a csv structured file.
    '''
    def __init__(self,fileName,fieldName,loglevel=Logger.info):
        Logger.__init__(self, loglevel)
        self.trace_stream("CSVOutput.__init__()")
        self._fileName = fileName
        self._fieldName = fieldName
        self._file = None

    #----# first level
    def open(self,mode='w+'):
        self.trace_stream("CSVOutput.open()")
        self._file = open(self._fileName,mode)
    def close(self):
        self.trace_stream("CSVOutput.close()")
        self._file.close()
    def isOpen(self):
        self.trace_stream("CSVOutput.isOpen()")
        if self._file == None:
            return False
        return not self._file.closed
    def getSize(self):
        '''Return the size of the file this object manages in the biggest
        '''
        self.trace_stream("CSVOutput.getSize()")
        try:
            bytes = os.path.getsize(self._fileName)
            size_name = ("B","KB","MB","GB")
            i = int(math.floor(math.log(bytes,1024)))
            p = math.pow(1024,i)
            s = round(bytes/p,2)
            if (s > 0):
                return (s,size_name[i])
        except Exception,e:
            self.error_stream("getting file size:",e)
        return (0,"B")
    def writeHeader(self):
        self.trace_stream("CSVOutput.writeHeader()")
        if self.isOpen():
            self._file.write("Timestamp\tquality\t%s\n"%(self._fieldName))
    def writeEvent(self,event):
        '''Translate an event to a csv list structure and write it to the file.
        '''
        self.trace_stream("CSVOutput.writeEvent()")
        tstamp = "%s.%s"\
                 %(event.attr_value.time.tv_sec,event.attr_value.time.tv_usec)
        quality = "%s"%(event.attr_value.quality)
        line = "%s\t%s"%(tstamp,quality)
        if type(event.attr_value.value) == ndarray:
            value = "%s"%(event.attr_value.value.tolist())
            value = value.replace('[','')
            value = value.replace(']','')
            value = value.replace(', ','\t')
        else:
            print(".")
            value = event.attr_value.value
        line = "%s\t%s"%(line,value)
        #self.debug_stream(line)
        if self.isOpen():
            self._file.write("%s\n"%(line))
            self._file.flush()
#----# end class CSVOutput

from optparse import OptionParser
import signal
import sys

def signal_handler(signal, frame):
    log.warning_stream('You pressed Ctrl+C! Terminating the collection...')
    collector.stop()
    sys.exit(0)

#---- DEFAULT OPTIONS
DEFAULT_LOGLEVEL = "info"
DEFAULT_PHCTDEVICE = "bl34/di/phct-01"
DEFAULT_PHCTHISTOGRAM = "Histogram"

def main():
    parser = OptionParser()
    parser.add_option('',"--log-level",default=DEFAULT_LOGLEVEL,
                      help="Set log level: error,warning,info,debug,trace")
    parser.add_option('',"--device",default=DEFAULT_PHCTDEVICE,
                      help="Device name to use. If not said is used the "\
                           "default %s"
                      %(DEFAULT_PHCTDEVICE))
    parser.add_option('',"--attribute",default=DEFAULT_PHCTHISTOGRAM,
                      help="Attribute name to use. If not said is used the "\
                      "default %s"%(DEFAULT_PHCTHISTOGRAM))
    parser.add_option('',"--minutes-collecting",default=0,
                      help="Minutes with this process collecting. If not "\
                      "specified, until Ctrl+C or more than %d %s file output"
                      %(MAXOUTPUTSIZE,MAXOUTPUTUNIT))
    parser.add_option('',"--output",default=None,
                      help="To specify the file name to save the data.")
    (options, args) = parser.parse_args()
    if options.output == None:
        options.output = "%s_%s_%s"%(time.strftime("%Y%m%d_%H%M%S"),
                                     options.device.replace('/','_'),
                                     options.attribute)
    if not options.output.endswith('.csv'):
        options.output += ".csv"
    global log
    log = Logger(options.log_level)
    if not type(options.minutes_collecting) in [int,long,float]:
        try:
            options.minutes_collecting = int(options.minutes_collecting)
        except:
            try:
                options.minutes_collecting = long(options.minutes_collecting)
            except:
                try:
                    options.minutes_collecting = \
                                              float(options.minutes_collecting)
                    if options.minutes_collecting % 1 != 0:
                        options.minutes_collecting = \
                                              int(options.minutes_collecting)+1
                        log.warning_stream("Round by excess the time "\
                                           "collecting",
                                           options.minutes_collecting)
                except:
                    log.error_stream("Not understand %s as a integer")
                    sys.exit(-1)
    log.debug_stream("logLevel:        %s"%(options.log_level))
    log.info_stream( "device:          %s"%(options.device))
    log.info_stream( "attribute:       %s"%(options.attribute))
    log.debug_stream("time collecting: %s"%(options.minutes_collecting))
    log.info_stream( "output:          %s"%(options.output))
    global collector
    collector = Collector(options.device,options.attribute,
                          options.minutes_collecting,options.output,
                          options.log_level)
    signal.signal(signal.SIGINT, signal_handler)
    collector.start()
    sys.exit(0)

if __name__ == '__main__':
    main()
