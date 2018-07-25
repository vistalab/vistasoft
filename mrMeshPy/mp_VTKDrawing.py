#!/usr/bin/python

'''
Commands that allow surface Drawing for meshes

Currently the user enters "draw mode" which stops any further 
zooming / rotation in the vtk window. Left clicks on the surface
make black dots at selected vertices. Right clicking closes the
loop and extracts a surface enclosed by the boundary.

The user can toggle the draw mode on and off to re-enable 
rotation or zooming.

Currently the current mode / reset (to start a new ROI) is done
via the drop-down menu - #TODO we could enable key bindings.

Andre' Gouws 2017
'''


import vtk
from numpy import *

debug = True



def drawingPickPoint(obj, ev):

    if obj.inDrawMode == 1:

        try: #TODO will this capture non-pick events?
            #get the pick position
            if debug: print "started pick"
            obj.GetPicker().Pick(obj.GetEventPosition()[0], obj.GetEventPosition()[1], 0,  obj.GetRenderWindow().GetRenderers().GetFirstRenderer())
            if debug: print "ended pick"
            if debug: print(obj.GetPicker().GetPointId())
            currPickPointID = obj.GetPicker().GetPointId()
            obj.pickedPointIds.append(currPickPointID) # append to place holder for picked vtk point IDs so we can track   

            ##draw on the selected vertices -just change each selected vertex for now -- we'll join the dots later
            
            # get the required surface

            currPolyData = obj.GetPicker().GetActor().GetMapper().GetInput()
            if debug: print(currPolyData.GetPointData().GetScalars().GetValue(currPickPointID))
            
            # append orig value to place holder for picked vtk point scalar values so we can revert
            obj.pickedPointOrigValues.append(currPolyData.GetPointData().GetScalars().GetTuple(currPickPointID))

            if debug: print(currPolyData.GetPointData().GetScalars().GetTuple(currPickPointID))
            
            # now change the colour at the picked vertex
            currPolyData.GetPointData().GetScalars().SetTuple(currPickPointID,(0,0,0,255)) #black for char array
            if debug: print(currPolyData.GetPointData().GetScalars().GetTuple(currPickPointID))

            # notify the stream that there has been a change
            currPolyData.Modified()
            obj.GetPicker().GetActor().GetMapper().Modified()
            obj.Render()
         
            # handle non-pick events or append pick point to list for later drawing
            if obj.GetPicker().GetPointId() != -1: #catch non-picks 
                obj.pickedPoints.InsertNextPoint(obj.GetPicker().GetPickPosition()[0], obj.GetPicker().GetPickPosition()[1], obj.GetPicker().GetPickPosition()[2])
            else:
                print('no point here! .. skipping')
        except:
            print('ignored left mouse click - outside the object? - no point EXACTLY here? - Try again')
            
    else:
        if debug: print('ignored left mouse click - not in draw mode')
        pass
      


def drawingMakeROI(obj, ev):

    if obj.inDrawMode == 1:
        print('closing and filling ROI')
        
        # get the required surface
        currPolyData = obj.GetPicker().GetActor().GetMapper().GetInput()
        
        #  ... and points
        currPoints = obj.pickedPoints

        # we're not actually going to change the original: we're going to clip out the region we want and 
        #  show it as a separate surface "patch" - this allows easy control of transparency/colour etc
        
        # a vtk selection tool that loops around our points
        if debug: print "before select polydata"
        selecta = vtk.vtkSelectPolyData()
        selecta.SetInputData(currPolyData)
        selecta.SetLoop(currPoints)
        selecta.GenerateSelectionScalarsOn()
        ## selecta.SetSelectionModeToSmallestRegion()
        selecta.SetSelectionModeToLargestRegion()
        selecta.Update()
        if debug: print "after select polydata"


        ## TODO - consider a different clipping function
        ## the one below appears to clip front AND back surfaces?
        #loop = vtk.vtkImplicitSelectionLoop()
        #loop.SetLoop(currPoints)
        #clipROI = vtk.vtkExtractPolyDataGeometry()
        #clipROI.SetInputData(currPolyData)
        #clipROI.SetImplicitFunction(loop)
        #clipROI.ExtractBoundaryCellsOn()
        #clipROI.PassPointsOff()
        #clipROI.Update()


        # the tool that actually clips out the selected region
        clipROI = vtk.vtkClipPolyData()
        clipROI.SetInputConnection(selecta.GetOutputPort())
        clipROI.Update()
        

        if debug: print(clipROI.GetOutput())

        # --- try to get an ROI
        if clipROI.GetOutput().GetNumberOfPoints() == 0:
            #loop could not clip data for some reason - we need to clean up
            obj.pickedPoints = vtk.vtkPoints() #new
            #stop drawing mode and reset the interactor to normal behaviour
            obj.inDrawMode = 0
            
            print 'Error while trying to close the ROI loop - resetting colours - please try again.'
            print obj.ScalarsCopyForRevert

            tmpScalarsCopyForRevert = vtk.vtkUnsignedCharArray()
            tmpScalarsCopyForRevert.DeepCopy(obj.ScalarsCopyForRevert)

            obj.curr_polydata.GetPointData().SetScalars(obj.ScalarsCopyForRevert)
            obj.curr_polydata.Modified()                            

            obj.ScalarsCopyForRevert = tmpScalarsCopyForRevert; #AND LOCK IN CURRENT STATE

            obj.curr_smoother.Update()
            obj.curr_mapper.SetColorModeToDefault()
            obj.curr_mapper.Modified()

            style = vtk.vtkInteractorStyleTrackballCamera()
            obj.SetInteractorStyle(style)

            obj.ren.Render()
            obj.Render()

            obj.parent_ui.statusbar.showMessage("Failed to close and fill ROI! Perhaps the surface is too spikey? - try smoothing.")

        else:

            ## -- track the point IDs
            # unfortunately the clip tool does not keep a reference of the original surface
            # point IDs (that we need to send bakc to other programs later
            #  -- we need a pretty nasty bit or code to track the xyz positions extracted 
            #     so that we can go back to the original surface and label these


            # first, get the xyz position of all points in original surface
            origDat = currPolyData.GetPoints().GetData()
            origArr = []
            
            for i in range(currPolyData.GetNumberOfPoints()):        
                origArr.append(origDat.GetTuple(i))


            # next get the xyz position of select points
            selectedDat = clipROI.GetOutput().GetPoints().GetData()
            selectedArr = [] #place holder for loop

            if debug: print(selectedDat)
            
            for i in range(clipROI.GetOutput().GetNumberOfPoints()):        
                selectedArr.append(selectedDat.GetTuple(i)) #xyz

            ## now find matching indices in original using numpy manipulation
            numpyOrigArr = array(origArr)
            numpySelectedArr = array(selectedArr)

            #if debug:
            #    numpyOrigArr.tofile('orig.txt',',')
            #    numpySelectedArr.tofile('new.txt',',')

            # TODO - we only check the first 6 characters of the coordinate data - this may cause precision issues later - check
            origAll = char.array(numpyOrigArr[:,0],'S6') + '-' + char.array(numpyOrigArr[:,1],'S6') + '-' + char.array(numpyOrigArr[:,2],'S6')
            selectedAll = char.array(numpySelectedArr[:,0],'S6') + '-' + char.array(numpySelectedArr[:,1],'S6') + '-' + char.array(numpySelectedArr[:,2],'S6')

            # and pipe it back to the original
            obj.filledROIPoints = where(in1d(origAll, selectedAll))[0]
            obj.ROI_ready = 1

            if debug: print(obj.filledROIPoints)
            if debug: print(size(obj.filledROIPoints))


            ## -- back to drawing
            # draw the new surface
            roiMapper = vtk.vtkPolyDataMapper()
            roiMapper.SetInputConnection(clipROI.GetOutputPort())
            roiMapper.ScalarVisibilityOff()
            roiMapper.Update()
            
            roiActor = vtk.vtkActor()
            roiActor.SetVisibility(1)
            roiActor.SetMapper(roiMapper)
            roiActor.GetProperty().SetOpacity(0.5)
            roiActor.GetProperty().SetColor(1.0,1.0,1.0)

            obj.roiActor = roiActor;
            obj.ren.AddActor(obj.roiActor)
            obj.Render()

            #stop drawing mode and reset hte interactor to normal behaviour
            obj.inDrawMode = 0

            #remove our black dots
            tmpScalarsCopyForRevert = vtk.vtkUnsignedCharArray()
            tmpScalarsCopyForRevert.DeepCopy(obj.ScalarsCopyForRevert)

            obj.curr_polydata.GetPointData().SetScalars(obj.ScalarsCopyForRevert)
            obj.curr_polydata.Modified()                            

            obj.ScalarsCopyForRevert = tmpScalarsCopyForRevert; #AND LOCK IN CURRENT STATE

            obj.curr_smoother.Update()
            obj.curr_mapper.SetColorModeToDefault()
            obj.curr_mapper.Modified()

            style = vtk.vtkInteractorStyleTrackballCamera()
            obj.SetInteractorStyle(style)

            # and clean up for the next loop? TODO? - or button to reset?
            obj.pickedPoints = vtk.vtkPoints() #new

    else:
        if debug: print('ignored right mouse click - not in draw mode')
        pass















