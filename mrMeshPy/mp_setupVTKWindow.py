#!/usr/bin/python

'''
This module sets up a VTK window instance for each new
mesh instance sent from mrVista

Andre' Gouws 2017
'''


from PyQt5 import QtCore, QtGui, QtNetwork, QtWidgets
from QVTKRenderWindowInteractor import QVTKRenderWindowInteractor

import vtk

debug = False


# add a new VTK window as an extra tab in the Main window's tab widget
def mrMeshVTKWindow(parentUI, theMeshInstance, data):
    _translate = QtCore.QCoreApplication.translate
    
    #create a new vtkWidget, appending to the list of exisitng widgets
    if debug: print(parentUI)
    newVTKWidgetInstance = QVTKRenderWindowInteractor(parentUI.centralwidget)
    parentUI.vtkInstances.append(newVTKWidgetInstance)

    currMeshCount = (len(parentUI.vtkInstances))
    
    # we have to make a new tab and layout for it to go to.
    parentUI.newTab = QtWidgets.QWidget()
    sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.MinimumExpanding, QtWidgets.QSizePolicy.MinimumExpanding)
    sizePolicy.setHorizontalStretch(0)
    sizePolicy.setVerticalStretch(0)
    sizePolicy.setHeightForWidth(parentUI.newTab.sizePolicy().hasHeightForWidth())
    parentUI.newTab.setSizePolicy(sizePolicy)
    parentUI.newTab.setObjectName("tab%s" %currMeshCount)
    parentUI.gridLayoutTabNew = QtWidgets.QGridLayout(parentUI.newTab)
    parentUI.gridLayoutTabNew.setContentsMargins(0, 0, 0, 0)
    parentUI.gridLayoutTabNew.setObjectName("gridLayoutTab%s" %currMeshCount)
    parentUI.gridLayoutVTKWinNew = QtWidgets.QGridLayout()
    parentUI.gridLayoutVTKWinNew.setObjectName("gridLayoutVTKWin%s" %currMeshCount)
    parentUI.gridLayoutTabNew.addLayout(parentUI.gridLayoutVTKWinNew, 0, 0, 1, 1)
    
    parentUI.gridLayoutVTKWinNew.addWidget(newVTKWidgetInstance, 0, 0, 1, 1)
    parentUI.tabWidget.addTab(parentUI.newTab, "Mesh-%s" %theMeshInstance)

    # have to set the resize policy now
    sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.MinimumExpanding, QtWidgets.QSizePolicy.MinimumExpanding)
    parentUI.vtkInstances[-1].setSizePolicy(sizePolicy)
    parentUI.vtkInstances[-1].ren = vtk.vtkRenderer()
    parentUI.vtkInstances[-1].GetRenderWindow().AddRenderer(parentUI.vtkInstances[-1].ren)
    parentUI.vtkInstances[-1].iren = parentUI.vtkInstances[-1].GetRenderWindow().GetInteractor()
    parentUI.gridLayoutVTKWinNew.addWidget(parentUI.vtkInstances[-1], 0, 0, 1, 1)

    parentUI.tabWidget.setCurrentIndex(len(parentUI.vtkInstances)-1) #zero index
    parentUI.tabWidget.update()

    style = vtk.vtkInteractorStyleTrackballCamera()
    parentUI.vtkInstances[-1].SetInteractorStyle(style)

    # flip the camera 
    parentUI.vtkInstances[-1].ren.GetActiveCamera().SetViewUp(0,-1,0)

    if data == 'debug':
        loadTestVTKWindow(parentUI)
    else:
        initializeEmptyVTKWindowInstance(parentUI)
    print('Finished setting up new VTK window instance ...')

    

# just set up an empty window
def initializeEmptyVTKWindowInstance(parentUI):
    parentUI.vtkInstances[-1].ren.ResetCamera()
    parentUI.vtkInstances[-1].iren.Start()


#debug testing content for VTK window instance
def loadTestVTKWindow(parentUI):

    cube = vtk.vtkCubeSource()
    cube.SetXLength(200)
    cube.SetYLength(200)
    cube.SetZLength(200)
    cube.Update()
    cm = vtk.vtkPolyDataMapper()
    cm.SetInputConnection(cube.GetOutputPort())
    ca = vtk.vtkActor()
    ca.SetMapper(cm)
    parentUI.vtkInstances[-1].ren.AddActor(ca)

    axesActor = vtk.vtkAnnotatedCubeActor();
    axesActor.SetXPlusFaceText('R')
    axesActor.SetXMinusFaceText('L')
    axesActor.SetYMinusFaceText('H')
    axesActor.SetYPlusFaceText('F')
    axesActor.SetZMinusFaceText('P')
    axesActor.SetZPlusFaceText('A')
    axesActor.GetTextEdgesProperty().SetColor(1,1,0)
    axesActor.GetTextEdgesProperty().SetLineWidth(2)
    axesActor.GetCubeProperty().SetColor(0,0,1)
    axes = vtk.vtkOrientationMarkerWidget()
    axes.SetOrientationMarker(axesActor)
    axes.SetInteractor(parentUI.vtkInstances[-1].iren)

    parentUI.vtkInstances[-1].ren.ResetCamera()
    parentUI.vtkInstances[-1].iren.Start()


