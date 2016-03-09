#!/usr/bin/env python
# -*- coding:utf-8 -*- 


##############################################################################
## license : GPLv3+
##============================================================================
##
## File :        PicoHarpGui.py
## 
## Project :     Measure Filling Pattern Graphical interface based in Taurus
##
## $Author :      sblanch$
##
## $Revision :    $
##
## $Date :        $
##
## $HeadUrl :     $
##============================================================================
##
##        (c) - Controls Software Section - Alba synchrotron (cells)
##############################################################################

from PicoHarpComponents import Component
import sys
from taurus.core.util import argparse
from taurus.external.qt import Qt,QtGui
from taurus import Logger
from taurus.qt.qtgui.application import TaurusApplication
from taurus.qt.qtgui.taurusgui import TaurusGui
from widgets import *

DEVICESERVERNAME = 'PH_PhotonCounter'


MODELS = 'models'
TYPE = 'type'


class MainWindow(TaurusGui):
    def __init__(self, parent=None):
        TaurusGui.__init__(self)
        self._components = None
        self.initComponents()
        self.prepareJorgsBar()
        self.loadDefaultPerspective()
        self.splashScreen().finish(self)

    panels = {'Histogram':{MODELS:['Histogram'],
                           TYPE:HistogramPlot},
              'Channel0':{MODELS:['ZeroCrossCh0','LevelCh0','syncdivider'],
                          TYPE:Channel0Form},
              'Channel1':{MODELS:['ZeroCrossCh1','LevelCh1'],
                          TYPE:Channel1Form},
              'Acquisition':{MODELS:['Resolution','binning','offset',
                                     'AcquisitionTime','ElapsedMeasTime',
                                     'OverflowStopper',
                                     'OverflowStopperThreshold'],
                             TYPE:AcquisitionForm},
              'Monitor':{MODELS:['CountRateCh0','CountRateCh1','IntegralCount',
                                 'HistogramMaxValue'],
                         TYPE:MonitorForm},
              'Status':{MODELS:['State','Status','Warnings'],
                        TYPE:StateForm},
              'Commands':{TYPE:PhCtCommands}
             }

    def initComponents(self):
        self._components = {}
        for panel in self.panels:
            self.splashScreen().showMessage("Building %s panel"%(panel))
            if self.panels[panel].has_key(MODELS):
                attrNames = self.panels[panel][MODELS]
                haveCommands = False
            else:
                attrNames = None
                haveCommands = True
            if self.panels[panel].has_key(TYPE):
                widget = self.panels[panel][TYPE]
            else:
                widget = None#FIXME
            self._components[panel] = Component(self,name=panel,
                                            widget=widget,attrNames=attrNames,
                                            haveCommands=haveCommands)
        self._selectorComponent()

    def prepareJorgsBar(self):
        #Eliminate one of the two taurus icons
        self.jorgsBar.removeAction(self.jorgsBar.actions()[0])

    def loadDefaultPerspective(self):
        try:
            self.loadPerspective(name='default')
        except:
            QtGui.QMessageBox.warning(self,
                            "No default perspective",
                            "Please, save a perspective with the name "\
                            "'default' to be used when launch")

    def _selectorComponent(self):
        self.splashScreen().showMessage("Building device selector")
        #create a TaurusDevCombo
        self._selector = TaurusDevCombo(self)
        #populate the combo
        self.splashScreen().showMessage("Searching for %s device servers"
                                        %(DEVICESERVERNAME))
        self._selector.setModel(DEVICESERVERNAME)
        self.splashScreen().showMessage("Found %s device servers"
                                     %(self._selector.getSelectedDeviceName()))
        #attach it to the toolbar
        self.selectorToolBar = self.addToolBar("Model:")
        self.selectorToolBar.setObjectName("selectorToolBar")
        self.viewToolBarsMenu.addAction(self.selectorToolBar.toggleViewAction())
        self.selectorToolBar.addWidget(self._selector)
        #subscribe model change
        self._modelChange()
        self._selector.modelChosen.connect(self._modelChange)

    def _modelChange(self):
        newModel = self._selector.getSelectedDeviceName()
        if newModel != self.getModel():
            self.debug("Model has changed from %r to %r"
                       %(self.getModel(),newModel))
            self.setModel(newModel)
            for component in self._components.keys():
                self._components[component].devName = newModel


def main():
    parser = argparse.get_taurus_parser()
    parser.add_option("--model")
    app = TaurusApplication(sys.argv, cmd_line_parser=parser,
                      app_name='ctdiPicoHarp300', app_version='0.9',
                      org_domain='ALBA', org_name='ALBA')
    options = app.get_command_line_options()
    ui = MainWindow()
    if options.model != None:
        ui.setModel(options.model)
    ui.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()