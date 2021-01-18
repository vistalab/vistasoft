#!/usr/bin/python

'''
VTK engine room for mrMeshPy viewer 

The main vtk processing is done by functions here - although some hardcore 
processing is handled in subroutines of other imported modules.

A core concept here is the tracking (kepping in scope) or the "targetVTKWindow"
 - this is a vtkRenderWindowInteractor instance in the main program UI (user
interface) - by creatoing multiple instances of vtk windows we can load 
multiple meshes. Some functions reference this specifically with a reference
index passed from mrVista --- mainWindowUI.vtkInstances[int(theMeshInstance)]
while others just referene the most recently added instance (e.g. when adding
a new mesh) --- mainWindowUI.vtkInstances[-1]

Note that it is the mainWindowUI that is passed to all functions so that all
funcitons have the content of the main window in scope.

Andre' Gouws 2017
'''


import vtk
from numpy import *
import time

from vtk.util import numpy_support

debug = True

# local modules
from mp_unpackIncomingData import unpackData
from mp_VTKProcessing import *
from mp_VTKDrawing import *



def loadNewMesh(currVTKInstance, commandArgs, mainWindowUI, the_TCPserver):
    
    #first get all the data we are expecting from the server
    ## NB this assumes that the order of sending by the server is 
    #    1) vertices
    #    2) triangles
    #    3) color data r (rgba) for each vertex
    #    4) color data g (rgba) for each vertex
    #    5) color data b (rgba) for each vertex
    #    6) color data a (rgba) for each vertex


    if debug:
        print('received request for new mesh with Args:')
        print(commandArgs)

    # sanity check
    if ('vertices' in commandArgs[0]) and ('triangles' in commandArgs[1]):
        pass
    else:
        return "error - expecting vertices, then triangles!"


    # load the surfaces data
    verticesArgs = commandArgs[0].strip().split(',')
    vertices = unpackData(verticesArgs[1], int(verticesArgs[2]), the_TCPserver)
    vertices = array(vertices,'f')
    vertices = vertices.reshape((len(vertices)/3,3))   

    trianglesArgs = commandArgs[1].strip().split(',')
    triangles = unpackData(trianglesArgs[1], int(trianglesArgs[2]), the_TCPserver)
    triangles = array(triangles,'f')
    if debug: print(triangles)
    triangles = triangles.reshape((len(triangles)/3,3))    
    if debug: print(triangles)
               
    # load the surface colour data
    rVecArgs = commandArgs[2].strip().split(',')
    r_vec = unpackData(rVecArgs[1], int(rVecArgs[2]), the_TCPserver)
    r_vec = array(r_vec,'uint8')
    if debug: print(r_vec)
    
    gVecArgs = commandArgs[3].strip().split(',')
    g_vec = unpackData(gVecArgs[1], int(gVecArgs[2]), the_TCPserver)
    g_vec = array(g_vec,'uint8')
    
    bVecArgs = commandArgs[4].strip().split(',')
    b_vec = unpackData(bVecArgs[1], int(bVecArgs[2]), the_TCPserver)
    b_vec = array(b_vec,'uint8')

    aVecArgs = commandArgs[5].strip().split(',')
    a_vec = unpackData(aVecArgs[1], int(aVecArgs[2]), the_TCPserver)
    a_vec = array(a_vec,'uint8')
        
    if debug:
        print(len(r_vec))
        print(len(g_vec))
        print(len(b_vec))
        print(len(a_vec))
      
    #combine into numpy array
    colorDat = squeeze(array(squeeze([r_vec,g_vec,b_vec,a_vec]),'B',order='F').transpose())

    # convert this to a VTK unsigned char array 
    scalars = numpy_support.numpy_to_vtk(colorDat,0)

    curr_scalars = vtk.vtkUnsignedCharArray()
    curr_scalars.DeepCopy(scalars)
  
   ## ---- ok, we hav the data, lets turn it into vtk stuff
    
   # Process vertices
    points = vtk.vtkPoints()
    for i in range(vertices.shape[0]):
        points.InsertPoint(i,vertices[i][0],vertices[i][1],vertices[i][2])

    # Process faces (triangles)
    polys = vtk.vtkCellArray()
    
    
    nTriangles = triangles.shape[0]
    for i in range(nTriangles):
        polys.InsertNextCell(3)
        for j in range(3):
            polys.InsertCellPoint(int(triangles[i][j]))

    # check  
    if debug: print(points)
    if debug: print(polys)
    if debug: print(scalars)
    if debug: print(currVTKInstance)

    # Assemble as PolyData
    polyData = vtk.vtkPolyData()
    polyData.SetPoints(points)
    polyData.SetPolys(polys)
    polyData.GetPointData().SetScalars(scalars)

    ## TODO ? smoothing on first load?

    smooth = vtk.vtkSmoothPolyDataFilter()
    smooth = vtk.vtkSmoothPolyDataFilter()
    smooth.SetNumberOfIterations(0)
    smooth.SetRelaxationFactor(0.0)
    smooth.FeatureEdgeSmoothingOff()
    smooth.SetInputData(polyData)
    
    pdm = vtk.vtkPolyDataMapper()
    pdm.SetScalarModeToUsePointData()
    pdm.SetInputConnection(smooth.GetOutputPort())

    actor = vtk.vtkActor()
    actor.SetMapper(pdm)

    iren = mainWindowUI.vtkInstances[-1]

    ## ---- engine room for drawing on the surface

    # add a picker that allows is top pick points on the surface
    picker = vtk.vtkCellPicker()
    picker.SetTolerance(0.0001)
    mainWindowUI.vtkInstances[-1].SetPicker(picker)
    mainWindowUI.vtkInstances[-1]._Iren.pickedPointIds = [] #place holder for picked vtk point IDs so we can track
    mainWindowUI.vtkInstances[-1].pickedPointIds = mainWindowUI.vtkInstances[-1]._Iren.pickedPointIds
    mainWindowUI.vtkInstances[-1]._Iren.pickedPointOrigValues = [] #place holder for picked vtk point IDs so we can track
    mainWindowUI.vtkInstances[-1].pickedPointOrigValues = mainWindowUI.vtkInstances[-1]._Iren.pickedPointOrigValues
    mainWindowUI.vtkInstances[-1]._Iren.pickedPoints = vtk.vtkPoints() #place holder for picked vtk point IDs so we can track
    mainWindowUI.vtkInstances[-1].pickedPoints = mainWindowUI.vtkInstances[-1]._Iren.pickedPoints
    mainWindowUI.vtkInstances[-1]._Iren.inDrawMode = 0 #TODO
    mainWindowUI.vtkInstances[-1].inDrawMode =  mainWindowUI.vtkInstances[-1]._Iren.inDrawMode

    # drawing functions imported from mp_VTKDrawing
    mainWindowUI.vtkInstances[-1].AddObserver('LeftButtonPressEvent', drawingPickPoint, 1.0)
    mainWindowUI.vtkInstances[-1].AddObserver('RightButtonPressEvent', drawingMakeROI, 1.0)

    ren = mainWindowUI.vtkInstances[-1].ren
    mainWindowUI.vtkInstances[-1]._Iren.ren = ren

    # ADD A LIGHT SOURCE TODO: MAKE THIS OPTIONAL/DEFAULT?
    lightKit = vtk.vtkLightKit()
    lightKit.SetKeyLightIntensity(0.5)
    # TODO: SOME OPTIONS TO EXPLORE
    #lightKit.MaintainLuminanceOn()
    #lightKit.SetKeyLightIntensity(1.0)
    ## warmth of the lights
    #lightKit.SetKeyLightWarmth(0.65)
    #lightKit.SetFillLightWarmth(0.6)
    #lightKit.SetHeadLightWarmth(0.45)
    ## intensity ratios
    ## back lights will be very dimm
    lightKit.SetKeyToFillRatio(1.)
    lightKit.SetKeyToHeadRatio(2.)
    lightKit.SetKeyToBackRatio(1.)
    lightKit.AddLightsToRenderer(ren)
   
    ren.AddActor(actor)
    ren.SetBackground(1,1,1)
    ren.ResetCamera()
    ren.Render()
    mainWindowUI.vtkInstances[-1].Render()
    
    # lets put some of the data objects in the scope of the
    # main window so that they can be manipulated later.
    mainWindowUI.vtkInstances[-1].curr_actor = actor
    mainWindowUI.vtkInstances[-1].curr_smoother = smooth
    mainWindowUI.vtkInstances[-1].curr_polydata = polyData
    mainWindowUI.vtkInstances[-1].curr_mapper = pdm
    mainWindowUI.vtkInstances[-1].curr_camera = ren.GetActiveCamera()
    # and the raw mesh coordinate data.. why not
    mainWindowUI.vtkInstances[-1].curr_points = points
    mainWindowUI.vtkInstances[-1].curr_polys = polys
    mainWindowUI.vtkInstances[-1].curr_scalars = curr_scalars #Deep copied


    # turns out that later processes access the inherited renderwindowinteractor (?) 
    # so lets put all the above in the scope of that too  
    mainWindowUI.vtkInstances[-1]._Iren.curr_actor = actor
    mainWindowUI.vtkInstances[-1]._Iren.curr_smoother = smooth
    mainWindowUI.vtkInstances[-1]._Iren.curr_polydata = polyData
    mainWindowUI.vtkInstances[-1]._Iren.curr_mapper = pdm
    mainWindowUI.vtkInstances[-1]._Iren.curr_camera = ren.GetActiveCamera()
    mainWindowUI.vtkInstances[-1]._Iren.curr_points = points
    mainWindowUI.vtkInstances[-1]._Iren.curr_polys = polys
    mainWindowUI.vtkInstances[-1]._Iren.curr_scalars = curr_scalars #Deep copied

    # and so we can access ui controls (e.g. statusbar) from the inherited window
    mainWindowUI.vtkInstances[-1]._Iren.parent_ui = mainWindowUI


    def KeyPress(obj, evt):
        key = obj.GetKeySym()
        if key == 'l':
            currVTKinstance = len(mainWindowUI.vtkInstances)
            print(key)
            print(mainWindowUI.vtkInstances[currVTKinstance-1])
    

    #let's also track key presses per instance esp for the draw routine :)
    mainWindowUI.vtkInstances[-1].AddObserver("KeyPressEvent",KeyPress)

    mainWindowUI.tabWidget.setCurrentIndex(len(mainWindowUI.vtkInstances)-1) #zero index



def smoothMesh(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver):
    
    #lets try to get the apt window
    try:
        targetVTKWindow = mainWindowUI.vtkInstances[mainWindowUI.vtkDict[theMeshInstance]] 
    except:
        print ('No mesh instance with id:%s currently available - may need a re-synch' %theMeshInstance)
        #return error
        return 1

    # lets show the correct tab
    mainWindowUI.tabWidget.setCurrentIndex(int(mainWindowUI.vtkDict[theMeshInstance])) 
    #mainWindowUI.tabWidget.repaint()
    mainWindowUI.tabWidget.update()


    #lets get the original data
    the_smoother = targetVTKWindow.curr_smoother
    the_mapper = targetVTKWindow.curr_mapper


    if debug: print(targetVTKWindow.curr_actor.GetMapper().GetInput().GetPointData().GetScalars())
    if debug: print(targetVTKWindow.curr_actor.GetMapper().GetInput().GetPointData().GetScalars().GetTuple(1000))

    #expecting a string that reads something like 'iterations,200,relaxationfactor,1.2'
    # sanity check
    if ('iterations' in commandArgs[0]) and ('relaxationfactor' in commandArgs[0]):
        smoothingArgs = commandArgs[0].strip().split(',')
        iterations = int(smoothingArgs[1])
        relaxationfactor = float(smoothingArgs[3])
    else:
        return "error - expecting vertices, then curvature, then triangles!"

    if debug: print 'starting smoothing callback'
    newActor = VTK_smoothing(the_smoother, the_mapper, iterations, relaxationfactor)

    if debug: print  'smoothing callback returned new actor'

    if debug: print  'removing old actor'
    targetVTKWindow.ren.RemoveActor(targetVTKWindow.curr_actor)
    if debug: print  'adding new actor'
    targetVTKWindow.ren.AddActor(newActor)

    if debug: print  'added new actor - changing curr actor pointer'
    targetVTKWindow.curr_actor = newActor #lets keep track

    if debug: print  'trying to update '    
    # run mesh update to reset the color map (smoothing "messes" this up)
    updateMeshData(theMeshInstance, [], mainWindowUI, the_TCPserver)
    if debug: print  'update completed'    

    #return success
    return 0


def updateMeshData(theMeshInstance, commandArgs, mainWindowUI, the_TCPserver):
    
    # here the base mesh is already loaded and we are simply updating with the
    # current View settings in from the vista session WITH THE COLOR VALUES FROM
    # VISTA - i.e. do not go through a lookuptable
    
    #lets try to get the apt window
    try:
        targetVTKWindow = mainWindowUI.vtkInstances[mainWindowUI.vtkDict[theMeshInstance]] 
    except:
        print ('No mesh instance with id:%s currently available - may need a re-synch' %theMeshInstance)
        #return error
        return 1
        

    # lets show the correct tab
    mainWindowUI.tabWidget.setCurrentIndex(int(mainWindowUI.vtkDict[theMeshInstance])) #zero index
    #mainWindowUI.tabWidget.repaint()
    mainWindowUI.tabWidget.update()


    #lets get the original data
    the_polyData = targetVTKWindow.curr_polydata
    the_mapper = targetVTKWindow.curr_mapper
    
    #first get all the data we are expecting from the server
    ## NB this assumes that the order of sending by the server is 
    #    1) r_vector - red component 
    #    2) g_vector - blue component 
    #    3) b_vector - green component 
    #    4) a_vector - aplha component


    if debug:
        print('received request for UPDATE DIRECT mesh with Args:')
        print(commandArgs)

    if len(commandArgs) != 0 : #new data has come from MATLAB so recompute

        # load the surfaces data
        rVecArgs = commandArgs[0].strip().split(',')
        r_vec = unpackData(rVecArgs[1], int(rVecArgs[2]), the_TCPserver)
        r_vec = array(r_vec,'uint8')
        if debug: print(r_vec)
        
        gVecArgs = commandArgs[1].strip().split(',')
        g_vec = unpackData(gVecArgs[1], int(gVecArgs[2]), the_TCPserver)
        g_vec = array(g_vec,'uint8')
        
        bVecArgs = commandArgs[2].strip().split(',')
        b_vec = unpackData(bVecArgs[1], int(bVecArgs[2]), the_TCPserver)
        b_vec = array(b_vec,'uint8')

        aVecArgs = commandArgs[3].strip().split(',')
        a_vec = unpackData(aVecArgs[1], int(aVecArgs[2]), the_TCPserver)
        a_vec = array(a_vec,'uint8')
            
        if debug:
            print(len(r_vec))
            print(len(g_vec))
            print(len(b_vec))
            print(len(a_vec))
          
        #combine into numpy array
        colorDat = squeeze(array(squeeze([r_vec,g_vec,b_vec,a_vec]),'B',order='F').transpose())

        # convert this to a VTK unsigned char array 
        vtkColorArray = numpy_support.numpy_to_vtk(colorDat,0)

        # keep a "deep" copy - this is to workaround some artifacts generated 
        #  by vtk algorithms (e.g. smoothing) that also smooth the color data
        #  on the surface and then automatically update the inherited color map
        #  - we allow vtk to do this but then overwrite the recomptued color
        #  map AFTER the algorithms have run

        deepCopyScalars = vtk.vtkUnsignedCharArray()
        deepCopyScalars.DeepCopy(vtkColorArray)
        targetVTKWindow.curr_scalars = deepCopyScalars

        #TODO - this may have impact on later processing - investigate

    else:
        # no new data from MATLAB, probably just an internal re-draw call 
        #   after something like smoothing - just grab the current deep 
        #   copy of the required scalars
        vtkColorArray = targetVTKWindow.curr_scalars


    # OK - we have the data - let's update the mesh 
    newActor = VTK_updateMesh(targetVTKWindow, vtkColorArray, mainWindowUI)

    targetVTKWindow.ren.AddActor(newActor)
    targetVTKWindow.ren.RemoveActor(targetVTKWindow.curr_actor)

    targetVTKWindow.curr_actor = newActor #lets keep track
    targetVTKWindow.ren.Render()
    targetVTKWindow.Render()
    print('success with direct mesh update routine')

    #return success
    return 0



## --------------------------------------------------------------------------------
# test example animation
def rotateMeshAnimation(currVTKInstance, commandArgs, mainWindowUI, the_TCPserver):

    #rotation args
    rotations = commandArgs[0].strip().split(',')
    rotations = unpackData(rotations[1], int(rotations[2]), the_TCPserver)

    if debug: print(rotations)

    targetVTKWindow = mainWindowUI.vtkInstances[int(currVTKInstance)] #NB zero indexing 
 
    camera = targetVTKWindow.ren.GetActiveCamera()
    if debug: print(camera)

    for i in range(len(rotations)):
        camera.Azimuth(rotations[i])
        #targetVTKWindow.ren.Render()
        targetVTKWindow.iren.Render() 

        time.sleep(0.02)  

    the_TCPserver.socket.write(str('send useful message back here TODO'))

## --------------------------------------------------------------------------------




