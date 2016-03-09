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

from taurus.external.qt import Qt
from taurus.qt.qtgui.panel import TaurusForm,TaurusCommandsForm
from taurus.qt.qtgui.plot import TaurusPlot,TaurusCurve

class PhCtCommands(TaurusCommandsForm):
    def __init__(self, parent = None, designMode = False):
        super(PhCtCommands,self).__init__(parent, designMode)
        commandsFilterList = [lambda x: x.cmd_name in ['Init',
                                                       'On','Off',
                                                       'Acquire','Start',
                                                       'Stop','Abort']]
        self.setViewFilters(commandsFilterList)
        self._splitter.setSizes([1,0])


class PhCtForm(TaurusForm):
    def __init__(self, parent = None,
                 formWidget = None,
                 buttons = None,
                 withButtons = False, 
                 designMode = False):
        super(PhCtForm,self).__init__(parent,formWidget,buttons,
                            withButtons,designMode)


AcquisitionForm = PhCtForm


Channel0Form = PhCtForm


Channel1Form = PhCtForm


MonitorForm = PhCtForm


StateForm = PhCtForm


WargningForm = PhCtForm


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

