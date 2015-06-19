Control Software for the PicoHarp300
====================================

This repository contains the infrastructure made to integrate the instrument
[PicoHarp300](https://www.picoquant.com/products/category/tcspc-and-time-tagging-modules/picoharp-300-stand-alone-tcspc-module-with-usb-interface) 
to a [Tango](http://www.tango-controls.org/) control system and provide the 
user a [Taurus](http://www.taurus-scada.org) interface. There is also an 
[Epics](http://www.aps.anl.gov/epics/) 
[driver](http://controls.diamond.ac.uk/downloads/other/picoharp/2-0/README.html).

It is divided in 3 levels. First of all a [Cython](http://cython.org/) code to 
extend and pythonize the [c++ library provided by the manufacturer](http://www.picoquant.com/products/category/tcspc-and-time-tagging-modules/picoharp-300-stand-alone-tcspc-module-with-usb-interface). 
A second level is a Tango Device Server that will use the python module to 
access plugged instruments. And finally a Taurus interface to access the 
Tango Device and provide the user a graphical interface to work with the 
acquisitions.

In the [ALBA Synchrotron](http://www.cells.es/) we have a 
[calculation device](https://github.com/srgblnch/MeasuredFillingPattern) 
above the acquisition device of the Photon Counter (and can also have as data 
input an oscilloscope waveform) to measure the Filling Pattern.

More detailed information in the subdiretories:
* library: the cython code
* src: the tango device server
* taurusgui: the taurus description to launch the gui.

