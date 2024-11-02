#!/usr/bin/python

'''
Command module for mrMeshPy viewer

Commands and data are passed here from matab via the mrMeshPyServer.

Matlab sends a string in one transaction giving a command to the 
visualisation module. This command either performs an explicit
function in the viewer (e.g. rotate the camera 90 degrees) or the
commnd describes the configuration/content of a large data chunk to
will be sent in the subsequent transaction so that we know how to
unpack the data, and how to process it (e.g. 70,000 floating point
numbers which are scalar values to show as an amplitude map. 

Each command string is interpreted by the mp_commandInterpret module.

N.B. - currently command strings have a maximum length of 1024 bytes.

Commands are specifically ordered, semi-colon seperated strings which are 
unpacked to describe what the user is trying to do / send from matlab.
Commands have a MINIMUM LENGTH of 6 arguments and have the following 
structure and item order (zero-indexed)

0 - "cmd"  -- always this, identifies it as a cmd :)
1-3 - place holders 
4 - commandName - should match a command in mp_Commands file
5 - theMeshInstance - integer pointing to the the mesh window that we
            want to operate on
6 onwards - commandArgs - a list of comma-separated pairs of arguments 
            to characterise the processing of the incoming data
            blob or apply some settings to the viewport -
            CAN BE EMPTY but must be set to []



Andre' Gouws 2017
'''

import vtk

    
import scipy.io #so we can read .mat files
import vtk
import vtk.util.numpy_support
from numpy import *


#local modules
from mp_setupVTKWindow import mrMeshVTKWindow
from mp_VTKRoutines import *
from mp_SendFunctions import *


debug = True


# master command handler

def run_mp_command(commandName, commandArgs, theMeshInstance, mainWindowUI, the_TCPserver):

    if commandName == 'loadNewMesh':
        mainWindowUI.statusbar.showMessage(' ... attempting to load new mesh ...')  

        # TODO - index will now be a new entry at the end of the exisitng .ui.vtkInstances list
        newIndex = len(mainWindowUI.vtkInstances) #could be zero

        # create an entry in the vtkDict to link the unique mesh ID to where it is stored
        #  in the vtkInstances list
        mainWindowUI.vtkDict[theMeshInstance] = newIndex
        
        # add a new tab with a new wVTK window
        mrMeshVTKWindow(mainWindowUI, theMeshInstance, 'None')

        mainWindowUI.tabWidget.setCurrentIndex(newIndex) #zero indexed 
        mainWindowUI.tabWidget.update()
        
        #load data and generate the mesh
        loadNewMesh(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver)
        mainWindowUI.statusbar.showMessage(' ... New mesh Loaded ...')
        #the_TCPserver.socket.write(str('send useful message back here TODO'))
        the_TCPserver.socket.write(str('1001'))   
        if debug: print mainWindowUI.vtkDict
        


    elif commandName == 'smoothMesh':
        mainWindowUI.statusbar.showMessage(' ... attempting to smooth mesh with id %s ...' %(theMeshInstance))
        #load data and generate the mesh
        err = smoothMesh(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver)
        if err == 0:        
            mainWindowUI.statusbar.showMessage(' ... Finished smoothing mesh with id %s ...' %(theMeshInstance))
            the_TCPserver.socket.write(str('Mesh smooth complete'))
        else:
            mainWindowUI.statusbar.showMessage(' ... Error trying to smooth mesh with id %s ...' %(theMeshInstance))
            the_TCPserver.socket.write(str('Mesh smooth failed'))            


    elif commandName == 'updateMeshData':
        mainWindowUI.statusbar.showMessage(' ... updating mesh with id %s with current View settings ...' %(theMeshInstance))
        #load data and send to the mesh
        err = updateMeshData(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver)
        if err == 0:       
            mainWindowUI.statusbar.showMessage(' ... Finished: updated data for mesh id %s ...' %(theMeshInstance))
            the_TCPserver.socket.write(str('Mesh update complete'))
        else:
            mainWindowUI.statusbar.showMessage(' ... Error trying to update mesh with id %s ...' %(theMeshInstance))
            the_TCPserver.socket.write(str('Mesh update failed'))  


    elif commandName == 'checkMeshROI':
        mainWindowUI.statusbar.showMessage(' ... MATLAB requested an ROI from mesh id %s ...' %(theMeshInstance))
        #get roi data (if exists) and send to matlab
        error = sendROIInfo(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver) #returns 1 or 0
        if error == 0:
            mainWindowUI.statusbar.showMessage(' ... ROI ready to send to MATLAB from mesh id %s...' %(theMeshInstance))
        else:
            mainWindowUI.statusbar.showMessage(' ... No ROI to send to MATLAB from mesh id %s...' %(theMeshInstance))
        the_TCPserver.socket.write(str('send useful message back here TODO'))


    elif commandName == 'sendROIVertices':
        mainWindowUI.statusbar.showMessage(' ... MATLAB requested an ROI from mesh id %s ...' %(theMeshInstance))
        #get roi data (if exists) and send to matlab
        error = sendROIVertices(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver) #returns 1 or 0
        if error == 0:
            mainWindowUI.statusbar.showMessage(' ... ROI ready to send to MATLAB from mesh id %s...' %(theMeshInstance))
        else:
            mainWindowUI.statusbar.showMessage(' ... No ROI to send to MATLAB from mesh id %s...' %(theMeshInstance))
        the_TCPserver.socket.write(str('send useful message back here TODO'))


    elif commandName == 'rotateMeshAnimation':
        mainWindowUI.statusbar.showMessage(' ... doing rotation animation ...')
        #really just for testing initially
        rotateMeshAnimation(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver)
        mainWindowUI.statusbar.showMessage(' ... Finished rotation animation ...')
        the_TCPserver.socket.write(str('send useful message back here TODO'))

    
    else:
        print('mrMeshPy received a command it did not recognise')
        the_TCPserver.socket.write(str('send cmd error message back here TODO'))    



