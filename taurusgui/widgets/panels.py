#!/usr/bin/env python

#############################################################################
##
## This file is part of Taurus, a Tango User Interface Library
## 
## http://www.tango-controls.org/static/taurus/latest/doc/html/index.html
##
## Copyright 2014 CELLS / ALBA Synchrotron, Bellaterra, Spain
## 
## Taurus is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## Taurus is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
## 
## You should have received a copy of the GNU Lesser General Public License
## along with Taurus.  If not, see <http://www.gnu.org/licenses/>.
##
#############################################################################

from taurus.qt.qtgui.panel import TaurusCommandsForm

class PhCtCommands(TaurusCommandsForm):
    def __init__(self, parent = None, designMode = False):
        TaurusCommandsForm.__init__(self, parent, designMode)
        commandsFilterList = [lambda x: x.cmd_name in ['Acquire','Abort',
                                                       'Start','Stop']]
        self.setViewFilters(commandsFilterList)

from taurus.qt.qtgui.panel import TaurusForm

class PhCtForm(TaurusForm):
    def __init__(self, parent = None,
                 formWidget = None,
                 buttons = None,
                 withButtons = True, 
                 designMode = False):
        TaurusForm.__init__(self,parent,formWidget,buttons,
                            withButtons,designMode)
        self._PhCtModel = ""
        
    def getModel(self):
        return self._PhCtModel
    def setModel(self,model):
        attrList = ["%s/%s"%(model,attrName) for attrName in self._attributes]
        TaurusForm.setModel(attrList)
        self._PhCtModel = model

class AcquisitionForm(PhCtForm):
    _attributes = ['resolution','binning','offset',
                   'acquisitiontime','ElapsedMeasTime',
                   'overflowstopper','overflowstopperthreshold']

class Channel0Form(PhCtForm):
    _attributes = ['zerocrossch0','levelch0','syncdivider']

class Channel1Form(PhCtForm):
    _attributes = ['zerocrossch1','levelch1']

class MonitorForm(PhCtForm):
    _attributes = ['countratech0','countratech1',
                   'integralcount','HistogramMaxValue']

class StateForm(PhCtForm):
    _attributes = ['State','Status']

from taurus.qt.qtgui.plot import TaurusPlot

class HistogramPlot(TaurusPlot):
    def __init__(self, parent=None, designMode=False):
        TaurusPlot.__init__(self, parent, designMode)
        self._curveName = None

    def getModel(self):
        return TaurusPlot.getModel(self).rsplit('/',1)[0]
    def setModel(self,model):
        #TODO: validate the model is a device with an attribute 'histogram'
        TaurusPlot.setModel(self, model+'/histogram')
        curveName = TaurusForm.getCurveNames()[0]
        self.info("Curve call: %s"%(curveName))
        self._histogramCurve = TaurusForm.getCurve(curveName)
        
