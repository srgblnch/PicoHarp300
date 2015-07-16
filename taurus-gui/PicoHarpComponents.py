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

from taurus.qt.qtgui.base import TaurusBaseComponent

class Component(TaurusBaseComponent):
    def __init__(self,parent,name=None,widget=None,
                 devName=None,attrNames=None,haveCommands=False):
        self._parent = parent
        self._name = None
        self._widget = None
        self._devName = None
        self._attrNames = None
        self._haveCommands = None
        super(Component,self).__init__(name)
        self.name = name
        self.widget = widget
        self.devName = devName
        self.attrNames = attrNames
        self.haveCommands = haveCommands

    def propertyLogger(self,tag,old,new):
        if not new:
            return
        if not old:
            self.info("Setting %s: %s"%(tag,new))
        else:
            self.info("Changing %s: %s to %s"%(tag,old,new))

    @property
    def parent(self):
        return self._parent

    @property
    def name(self):
        return self._name
    
    @name.setter
    def name(self,value):
        self.propertyLogger("Name",self._name,value)
        self._name = value

    @property
    def widget(self):
        return self._widget

    @widget.setter
    def widget(self,value):
        self.propertyLogger("Widget",self._widget,value)
        self._widget = value(parent=self._parent)
        self._doSetmodel()
        self._parent.createPanel(self._widget,name=self._name,permanent=True)

    @property
    def devName(self):
        return self._devName

    @devName.setter
    def devName(self,value):
        self.propertyLogger("DevName",self._devName,value)
        #TODO: check if it's a valid device name
        self._devName = value
        self._doSetmodel()

    @property
    def attrNames(self):
        return self._attrNames

    @attrNames.setter
    def attrNames(self,value):
        self.propertyLogger("AttrNames",self._attrNames,value)
        #TODO: check if it's a list of strings (possible attribute names)
        self._attrNames = value
        self._doSetmodel()
    
    @property
    def haveCommands(self):
        return self._haveCommands
    
    @haveCommands.setter
    def haveCommands(self,value):
        self.propertyLogger("haveCommands",self._haveCommands,value)
        self._haveCommands = bool(value)
        self._doSetmodel()
            
    def _doSetmodel(self):
        try:
            if hasattr(self._widget,'setModel'):
                if self._devName:
                    if self._setModelWithAttrs(self._devName):
                        return True
                    elif self._setModelWithCommands(self._devName):
                        return True
                    else:
                        self.error("No conditions for setModel()")
        except Exception,e:
            self.error("Cannot do setModel: %s"%(e))
        return False

    def _setModelWithAttrs(self,devName):
        if self._attrNames:
            model = []
            for attrName in self._attrNames:
                model.append("%s/%s"%(devName,attrName))
            self._widget.setModel(model)
            self.info("setmodel(%s)"%(self._widget.getModel()))
            return True
        return False
    
    def _setModelWithCommands(self,devName):
        if self.haveCommands:
            self.info("setmodel(%s)"%(self._devName))
            self._widget.setModel(self._devName)
            return True
        return False