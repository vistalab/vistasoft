## TODO header

import vtk
from numpy import pi

debug = True


def VTK_smoothing(the_smoother, the_mapper, iterations, relaxation_factor):
    
    # Standard way to perform mesh smoothing via relaxation in VTK.
    # I'm pretty sure this is a direct replication of what mrMesh was
    # doing before.

    if debug: print 'starting smoothing'
    the_smoother.SetNumberOfIterations(iterations)
    the_smoother.SetRelaxationFactor(relaxation_factor)
    the_smoother.Modified()
    the_smoother.Update()

    if debug: print 'finished smoothing -setting up mapper'    
    the_mapper.SetInputConnection(the_smoother.GetOutputPort())
    the_mapper.SetScalarModeToUsePointData()
    the_mapper.SetColorModeToDefault()
    the_mapper.Modified()

    if debug: print 'finished mapper -setting up actor'        
    newActor = vtk.vtkActor()
    newActor.SetMapper(the_mapper)
    if debug: print 'finished actor'        

    return newActor
    

def VTK_updateMesh(currVTKInstance, colorData, mainWindowUI):
    
    # user has send some new scalar values to be rendered on the mesh BUT COLORS ARE 
    # ALREADY CALCULATED IN MATLAB

    if debug: print(colorData)
    
    currVTKInstance.curr_polydata.GetPointData().SetScalars(colorData)
    currVTKInstance.curr_polydata.Modified()

    currVTKInstance.curr_smoother.Update()
    currVTKInstance.curr_mapper.SetColorModeToDefault()
    currVTKInstance.curr_mapper.Modified()

    # in case of error when drawing ROIs we can revert the color map
    # turns out that later processes access the inherited renderwindowinteractor (?) 
    # so lets put all the above in the scope of that
    currVTKInstance._Iren.ScalarsCopyForRevert = vtk.vtkUnsignedCharArray()
    currVTKInstance._Iren.ScalarsCopyForRevert.DeepCopy(colorData)

    newActor = vtk.vtkActor()
    newActor.SetMapper(currVTKInstance.curr_mapper)

    return newActor

    
    if debug: print('colorData processed in VTK_updateMeshDirect')
    


''' OBSOLETE if we use the direct color import - i.e. all colour handling done in matlab    
def VTK_updateMesh(currVTKInstance, newLUT, phaseData, cohData, cohThr, mainWindowUI):
    
    # user has send some new scalar values to be rendered on the mesh

    ## TODO - other data types - assuming phase for now
    # rescale phase data into range: 0-1024 to match lookup table
    rescaledPhaseData = phaseData/(2.0*pi)*1024.0
    
    curvature = currVTKInstance.curr_curvature
    
    scalars = vtk.vtkFloatArray()

    for i in range(len(rescaledPhaseData)):
        if cohData[i] >= float(cohThr): # apply threshold
            scalars.InsertNextValue(rescaledPhaseData[i])
        else:
            if curvature[i] < 0:
                scalars.InsertNextValue(1024+50)
            else:
                scalars.InsertNextValue(1024+150)
    
    currVTKInstance.curr_polydata.GetPointData().SetScalars(scalars)
    currVTKInstance.curr_polydata.Modified()

    currVTKInstance.curr_smoother.Update()

    currVTKInstance.curr_mapper.SetLookupTable(newLUT)
    currVTKInstance.curr_mapper.SetScalarRange(0,1224)
    currVTKInstance.curr_mapper.Modified()
    
    newActor = vtk.vtkActor()
    newActor.SetMapper(currVTKInstance.curr_mapper)

    return newActor

    
    if debug: print('here')

    
    
def VTK_buildLookupTable(r_vec, g_vec, b_vec):
    
    # we need to build custom colour lookup table that can show colour
    # data for vertices above threshold and grayscale anatomy at 
    # vertices that do nor reach threshold. 
    # I build a lookup table that is made up of two parts: the lower 
    # end of the table is a RGB colour map (entries 1-1024)- when we get
    # the scalar values from vista for the overlay data (e.g. phase) we 
    # rescale the incoming data into the range 1-1024 so that the scalar
    # values map explicitly onto a colour table value. 
    # The 'upper' part of the table (1025-1224) has grayscale values. In 
    # theory we could just have 2 extra entries in the table for light 
    # or dark gray, but interpolation in vtk can cause some odd effects
    # and color blending so we pad and extra 200 values onto the table
     
    
    #create an arbitrary LUT with 1224 entries, we'll overwrite this
    cLUT = vtk.vtkLookupTable()
    cLUT.SetHueRange(0,1)
    cLUT.SetValueRange(1,1)
    cLUT.SetSaturationRange(1,1)
    cLUT.SetNumberOfColors(1224)
    cLUT.Build() #build it
    
    # now overwrite it with the incoming RGB data for entries 1-1024 
    for i in range(1024):
        cLUT.SetTableValue(i,(r_vec[i],g_vec[i],b_vec[i],1))

    # and overwrite 1025-1124 with dark gray
    for i in range(1024,1124):
        cLUT.SetTableValue(i,(0.3,0.3,0.3,1))
        
    # and the overwrite 1125-1224 with light gray
    for i in range(1124,1224):
        cLUT.SetTableValue(i,(0.7,0.7,0.7,1))
        
    ## TODO - allow modulation of light/dark gray levels?
    
    # rebuild the table with these new values
    cLUT.Modified()
    
    
    return cLUT
'''
