//+============================================================================
//
// file :               PicoHarp.c
//
// description :        This file has been made to provide a python access to
//                      the PHLib to control a PicoHarp300 instrument.
//
// project :            TANGO
//
// author(s) :          S.Blanch-Torné
//
// Copyright (C) :      2014
//                      CELLS / ALBA Synchrotron,
//                      08290 Bellaterra,
//                      Spain
//
// This file is part of Tango.
//
// Tango is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tango is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Tango.  If not, see <http://www.gnu.org/licenses/>.
//
//-============================================================================

//Libraries for the python extension
#include <Python.h>

//Libraries for the PHLib
#include "phdefin.h"
#include "phlib.h"
#include "errorcodes.h"

/****
 * Request PHlib the version
 */
static PyObject* PicoHarpVersion(PyObject* self)
{
    char LIB_Version[8];
    PH_GetLibraryVersion(LIB_Version);
    return Py_BuildValue("s",LIB_Version);
}

static char PicoHarpVersion_docs[] =
    "__version__(): Get the current version of the PHlib\n";

/****
 * Describe the functions exported to python
 */
static PyMethodDef PicoHarp_funcs[] = {
    {"__version__", (PyCFunction)PicoHarpVersion,
     METH_NOARGS, PicoHarpVersion_docs},
    {NULL} /* Sentinel */
};

void initPicoHarp(void)
{
    //This is called when "import PicoHarp"
    Py_InitModule3("PicoHarp", PicoHarp_funcs,
                   "Extension module for the PHlib in python");
}

int main(int argc, char **argv) {
    Py_Initialize();
    return 0;
}
