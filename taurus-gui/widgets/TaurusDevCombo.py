#!/usr/bin/env python
# -*- coding:utf-8 -*- 

##############################################################################
## license : GPLv3+
##============================================================================
##
## File :        widgets/TaurusDevCombo.py
## 
## Project :     Widget to select one device from the given device server name
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

#?__docformat__ = 'restructuredtext'

import sys
from taurus.external.qt import Qt,QtCore
from taurus.qt.qtgui.util.ui import UILoadable
from taurus.qt.qtgui.panel import TaurusWidget
import taurus

@UILoadable(with_ui='_ui')
class TaurusDevCombo(TaurusWidget):
    modelChosen = QtCore.pyqtSignal()
    def __init__(self, parent=None, designMode=False):
        TaurusWidget.__init__(self, parent, designMode=designMode)
        self.loadUi()
        self._selectedDevice = ""
        self._ui.selectorCombo.currentIndexChanged.connect(self.selection)

    @classmethod
    def getQtDesignerPluginInfo(cls):
        ret = TaurusWidget.getQtDesignerPluginInfo()
        ret['module'] = 'widgets.TaurusDevCombo'
        ret['group'] = 'Taurus Views'
        ret['container'] = ':/designer/frame.png'
        ret['container'] = False
        return ret

    def setModel(self,model):
        self.getDeviceListByDeviceServerName(model)
        self._ui.selectorCombo.addItems(self._deviceNames.keys())

    def getDeviceListByDeviceServerName(self,deviceServerName):
        db = taurus.Database()
        foundInstances = db.getServerNameInstances(deviceServerName)
        self.debug("by %s found %d instances: %s."
                   %(deviceServerName,len(foundInstances),
                     ','.join("%s"%instance.name() \
                              for instance in foundInstances)))
        self._deviceNames = {}
        for instance in foundInstances:
            for i,devName in enumerate(instance.getDeviceNames()):
                if not devName.startswith('dserver'):
                    self._deviceNames[devName] = instance.getClassNames()[i]
        return self._deviceNames.keys()
    
    def selection(self,devName):
        if type(devName) == int:
            devName = self._ui.selectorCombo.currentText()
        if not devName in self._deviceNames.keys():
            self.warning("Selected device is not in the list of devices found!")
        self.debug("selected %s"%(devName))
        self._selectedDevice = devName
        self.modelChosen.emit()
    
    def getSelectedDeviceName(self):
        #self.debug("Requested which device was selected")
        return self._selectedDevice
    
    def getSelectedDeviceClass(self):
        try:
            return self._deviceNames[self._selectedDevice]
        except:
            self.error("Uou! As the selected device is not in the device "\
                       "instances found, its class is unknown")
            return "unknown"

def main():
    app = Qt.QApplication(sys.argv)
    w = TaurusDevCombo()
    w.setModel("MeasuredFillingPattern")
    w.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
