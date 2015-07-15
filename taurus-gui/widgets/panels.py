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

#TODO: widget to select the device
#      combo with all the Photon counters

#TODO: instrument warnings text messages

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

AcquisitionForm = TaurusForm

#class AcquisitionForm(PhCtForm):
#    _attributes = ['resolution','binning','offset',
#                   'acquisitiontime','ElapsedMeasTime',
#                   'overflowstopper','overflowstopperthreshold']

Channel0Form = TaurusForm

#class Channel0Form(PhCtForm):
#    _attributes = ['zerocrossch0','levelch0','syncdivider']

Channel1Form = TaurusForm

#class Channel1Form(PhCtForm):
#    _attributes = ['zerocrossch1','levelch1']

MonitorForm = TaurusForm

#class MonitorForm(PhCtForm):
#    _attributes = ['countratech0','countratech1',
#                   'integralcount','HistogramMaxValue']

StateForm = TaurusForm

#class StateForm(PhCtForm):
#    _attributes = ['State','Status']

WargningForm = TaurusForm

#class WargningForm(PhCtForm):
#    _attributes = ['Warnings']

from taurus.qt.qtgui.plot import TaurusPlot,TaurusCurve

#HistogramPlot = TaurusPlot

class HistogramPlot(TaurusPlot):
    pass
    def __init__(self, parent=None, designMode=False):
        TaurusPlot.__init__(self, parent, designMode)
        #self._curveName = None
        #TODO: XAxis related with the instrument resolution
        #TODO: Fix ranges on X and Y [0:65535]
        #TODO: can be play the colour of this curve to show quality?

    def getModel(self):
        return self._modelNames
    def setModel(self,model):
        '''sets the model of the Tango attribute that should be displayed in
           this TaurusPlot. But different from the superclass only one model
           in the list, two curves plot: one for the curve when quality is 
           changing and the other for when is valid.
        '''
        self.info("HistogramPlot model = %s"%(model))
        #Don't do: TaurusPlot.setModel(self,model)
        if type(model) == list and len(model) == 1:
            self._modelNames = [model[0]]
        elif type(model) == str:
            self._modelNames = [model]
        else:
            self.error("HistogramPlot wrong model type set! %s"%(type(model)))
            return
        #TODO: validate name corresponds with and attribute
        self.updateCurves(self._modelNames)
        self.emit(Qt.SIGNAL("modelChanged()"))
        #update the modelchooser list
        if self.DataImportDlg is not None:
            self.DataImportDlg.modelChooser.setListedModels(self._modelNames)
        
#        curveName = self.getCurveNames()[0]
#        self.info("Curve call: %s"%(curveName))
#        self._histogramCurve = self.getCurve(curveName)

    #TODO: two curves must be set up per model (in fact, only one model is 
    #      accepted).
        
class ChangingCurve(TaurusCurve):
    pass
class ValidCurve(TaurusCurve):
    pass