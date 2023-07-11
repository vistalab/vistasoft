#!/usr/bin/python

'''
Drop menu callback handlers for mrMeshPy

Andre' Gouws 2017

#TODO - workaround that doesn't require the parent UI to be global - needed for drawing routines
'''


import vtk

from mp_VTKDrawing import *

debug = True


global the_parent_UI


def Ui_setupMenuBarCallbacks(parent_UI):

    global the_parent_UI

    the_parent_UI = parent_UI;

    if debug: print('setting up menu bar callbacks')

    parent_UI.actionEnableDraw.triggered.connect(cb_MenuEnableDraw)
    parent_UI.actionDisableDraw.triggered.connect(cb_MenuDisableDraw)
    parent_UI.actionCloseAndFill.triggered.connect(cb_MenuCloseAndFill)
    parent_UI.actionStart_New_ROI.triggered.connect(startNewROI)
    parent_UI.actionSend_10_bytes_TCP.triggered.connect(send10Bytes)
    parent_UI.actionExport_Surface_to_stl.triggered.connect(cb_ExportToSTL)



def testMenuMessage():
    print('test message from mrMeshPy menu! - wait for it!')
    global the_parent_UI


def cb_MenuEnableDraw():
    global the_parent_UI
    #enable draw mode
    currentIndex = the_parent_UI.tabWidget.currentIndex()

    the_parent_UI.vtkInstances[currentIndex]._Iren.inDrawMode = 1 #TODO
    the_parent_UI.vtkInstances[currentIndex].inDrawMode =  the_parent_UI.vtkInstances[currentIndex]._Iren.inDrawMode
    style = vtk.vtkInteractorStyleUser()
    the_parent_UI.vtkInstances[currentIndex].SetInteractorStyle(style)
    the_parent_UI.statusbar.showMessage("In DRAW ROI Mode! - rotation/zoom disabled - (Menu-ROIs-Disable Draw to continue) ..")
    
    # it has become apparent that users may start drawing a new ROI before an old one is removed.
    # this can cause problems if the old temporary overlay surface is still present
    # what we'll do is detect if a closed roi surface is present, and - if so - remove it.
    
    try:
    #remove the overlaid roi actor
        the_parent_UI.vtkInstances[currentIndex]._Iren.ren.RemoveActor(the_parent_UI.vtkInstances[currentIndex]._Iren.roiActor)
        print "Removed an exiting temporary ROI surface to start a new one."
    except:
        pass
        

def cb_ExportToSTL():
    global the_parent_UI
    # export the current surface to stl file format
    # get the current viewed instance
    currentIndex = the_parent_UI.tabWidget.currentIndex()

    # extract the polydata from the surface as it is currently rendered for export
    # get the actor    
    act = the_parent_UI.vtkInstances[currentIndex].curr_actor
    polydata = act.GetMapper().GetInput()
    polydata.Modified()

    # open an stl exporter
    stl = vtk.vtkSTLWriter()
    stl.SetInputData(polydata)
    stl.SetFileName("/tmp/brain.stl")
    stl.Write()

def cb_MenuDisableDraw():
    global the_parent_UI
    #disable draw mode
    currentIndex = the_parent_UI.tabWidget.currentIndex()

    the_parent_UI.vtkInstances[currentIndex]._Iren.inDrawMode = 0 #TODO
    the_parent_UI.vtkInstances[currentIndex].inDrawMode =  the_parent_UI.vtkInstances[currentIndex]._Iren.inDrawMode
    style = vtk.vtkInteractorStyleTrackballCamera()
    the_parent_UI.vtkInstances[currentIndex].SetInteractorStyle(style)
    the_parent_UI.statusbar.showMessage("Draw mode disabled - normal rotation/zoom resumed ..")

def cb_MenuCloseAndFill():
    global the_parent_UI
    currentIndex = the_parent_UI.tabWidget.currentIndex()
    obj = the_parent_UI.vtkInstances[currentIndex]._Iren
    obj.inDrawMode = 1 #tmp reset
    drawingMakeROI(obj, None)
    style = vtk.vtkInteractorStyleTrackballCamera()
    the_parent_UI.vtkInstances[currentIndex].SetInteractorStyle(style)
    the_parent_UI.statusbar.showMessage("Closed and filled ROI ..")


def startNewROI():
    global the_parent_UI
    currentIndex = the_parent_UI.tabWidget.currentIndex()
    try:
        #remove the overlaid roi actor
        the_parent_UI.vtkInstances[currentIndex]._Iren.ren.RemoveActor(the_parent_UI.vtkInstances[currentIndex]._Iren.roiActor)
        
        # reset all pointers to ROI data
        the_parent_UI.vtkInstances[currentIndex]._Iren.inDrawMode = 0 #TODO
        the_parent_UI.vtkInstances[currentIndex]._Iren.pickedPointIds = [] #place holder for picked vtk point IDs so we can track
        the_parent_UI.vtkInstances[currentIndex]._Iren.pickedPointOrigValues = [] #place holder for picked vtk point IDs so we can track
        the_parent_UI.vtkInstances[currentIndex]._Iren.pickedPoints = vtk.vtkPoints() #place holder for picked vtk point IDs so we can track
        style = vtk.vtkInteractorStyleTrackballCamera()
        the_parent_UI.vtkInstances[currentIndex].SetInteractorStyle(style)
        the_parent_UI.statusbar.showMessage("Old ROI drawing removed. New ROI started - enable drawing mode to continue ...")
    except:
        print "Error while trying to remove an exisiting ROI actor - does one actually exist yet?"


def send10Bytes():
    global the_parent_UI
    the_parent_UI.TCP_server.socket.write('Ready,uint8,%i' %129860*1000) 

    
