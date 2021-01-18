#!/Users/lcladm/anaconda2/bin/python

# TODO - python path - assuming condo here 

## HEALTH WARNING - BETA CODE IN DEVELOPMENT ##

'''
This standalone application will build a mesh from a nifti classification file.
To keep the procedure as similar as possible to the way mrMesh used to do this,
we will keep this as a standalon application. Matlab reads in the segmented 
nifti file using vistasofts own nifti class handler meshBuild>mrmBuild>
meshBuildFromClass - we just dont use the old build_mesh mex file - we do that
bit and any smoothing in this application and send a mesh struture back to
matlab.

AG 2017
'''

import os,sys
import scipy
import vtk

from numpy import *
from scipy.io import loadmat, savemat
from vtk.util import numpy_support

debug = False

#TODO error handling
fileToLoad = sys.argv[1]
fileToSave = sys.argv[2]

# load the voxel data that has been dumped to disk
voxels = scipy.io.loadmat(fileToLoad)
mmPerVox = voxels['mmPerVox'][0]
if debug: print mmPerVox

voxels = voxels['voxels'] #unpack


if debug: print voxels

if debug: print shape(voxels)

extent = shape(voxels)
if debug: print extent
if debug: print extent[0]
if debug: print extent[1]
if debug: print extent[2]



###  ------------------------------------------------------------------------------
### this is faster but for now exactly replicate the way mrMesh sets up the volume array
# import voxels to vtk
dataImporter = vtk.vtkImageImport()
data_string = voxels.tostring()
dataImporter.CopyImportVoidPointer(data_string, len(data_string))
dataImporter.SetDataScalarTypeToUnsignedChar()
dataImporter.SetDataExtent(0, extent[2]-1, 0, extent[1]-1, 0, extent[0]-1) # TODO have to work this out
dataImporter.SetWholeExtent(0, extent[2]-1, 0, extent[1]-1, 0, extent[0]-1) # TODO have to work this out
dataImporter.SetDataSpacing(mmPerVox[0],mmPerVox[1],mmPerVox[2]) # TODO have to work this out
dataImporter.Update()
if debug: print dataImporter.GetOutput()

###  ------------------------------------------------------------------------------
'''


###  ------- the way mrMesh did it in mesh_build  --------------------------------
pArray = map(ord,voxels.tostring()) #unpack

pDims = shape(voxels)
scale = mmPerVox
iSizes = [pDims[0]+2, pDims[1]+2, pDims[2]+2]

nTotalValues = iSizes[0] * iSizes[1] * iSizes[2]

pClassValues = vtk.vtkUnsignedCharArray()
pClassValues.SetNumberOfValues(nTotalValues)

pClassData = vtk.vtkStructuredPoints()
pClassData.SetDimensions(iSizes[0], iSizes[1], iSizes[2])
pClassData.SetOrigin(-scale[0], -scale[1], -scale[2]) #???
pClassData.SetOrigin(-1, -1, -1) #???
pClassData.SetSpacing(scale[0], scale[1], scale[2])


for iSrcZ in range(pDims[2]):

    for iSrcY in range(pDims[1]):

        iSrcIndex = iSrcZ * pDims[1] * pDims[0] + iSrcY * pDims[0]
        iDstIndex = (iSrcZ+1) * iSizes[1] * iSizes[0] + (iSrcY+1) * iSizes[0] + 1

        for iSrcX in range(pDims[0]):

            fTemp = int(pArray[iSrcIndex])
            #if debug: print fTemp, 'iSrcIndex', iSrcIndex, 'iDstIndex', iDstIndex
            if fTemp>0: 
                pClassValues.SetValue(iDstIndex, 0)
            else:         
                pClassValues.SetValue(iDstIndex, 1)         


            iSrcIndex+=1
            iDstIndex+=1


pClassData.GetPointData().SetScalars(pClassValues)

pClassData.Modified()

if debug:
    spw = vtk.vtkStructuredPointsWriter()
    spw.SetFileTypeToASCII()
    spw.SetInputData(pClassData)
    spw.SetFileName("/tmp/test-mrMeshPy-structuredPoints.vtk")
    spw.Write()
    spw.Update()
        

'''

###  ------ Data volume is loaded and constructed - extract some surgfaces  -------------

mc = vtk.vtkMarchingCubes() # mc = vtk.vtkContourFilter() #- could use a contour filter instead?

mc.SetInputConnection(dataImporter.GetOutputPort()) # later - for use with direct imagedata import #mc.SetInputData(pClassData)
mc.SetValue(0,0.5) #extract 0-th surface at 0.5?
mc.ComputeGradientsOff()
mc.ComputeNormalsOff()
mc.ComputeScalarsOff()
mc.Update()


if debug:
    print mc.GetOutput()
    write = vtk.vtkPolyDataWriter()
    write.SetFileName('/htmp/test-mrMeshPy-marchingCubesOutput.txt')
    write.SetFileTypeToASCII()
    write.SetInputData(mc.GetOutput())
    write.Write()
    write.Update()


# ---- extract center surface - edges are normally extracted to (the cube around the edge of the volume)--------

confilter = vtk.vtkPolyDataConnectivityFilter()
confilter.SetInputConnection(mc.GetOutputPort())
confilter.SetExtractionModeToClosestPointRegion()
confilter.SetClosestPoint(extent[0]/2.0,extent[1]/2.0,extent[2]/2.0) # center of volume
confilter.Update()



# ---- Normals ---------------------

# normals already computed by mc algorithm so this code is obsolete
normals = vtk.vtkPolyDataNormals()
normals.ComputePointNormalsOn()
normals.SplittingOff()
normals.SetInputConnection(confilter.GetOutputPort())
#normals.SetInputData(discrete.GetOutput())
normals.Update()
print normals.GetOutput()

norm = normals.GetOutput().GetPointData().GetNormals()
output_normals = array(numpy_support.vtk_to_numpy(norm).transpose(),'d')

####if debug: print output_normals



# ---- Initial vertices - unsmoothed ---------------------
init_verts = normals.GetOutput().GetPoints().GetData()
output_init_verts = array(numpy_support.vtk_to_numpy(init_verts).transpose(),'d')

if debug: print output_init_verts


# ---- Polys (triangles) ---------------------
triangles = normals.GetOutput().GetPolys().GetData()
tmp_triangles = numpy_support.vtk_to_numpy(triangles)

# N.B. the polygon data returned here have 4 values for poly - the first is the number
# of vertices that describe the polygo (ironically always 3) and the next 3 are the 
# indices of the vertices that make up the polygon

# so first we need to reshape data from a vector
tmp_triangles = reshape(tmp_triangles,(len(tmp_triangles)/4,4))

# and then we drop the first column (all 3's)
output_triangles = array((tmp_triangles[:,1:4]).transpose(),'d') #remember zero index here, add one for matlab

if debug: print output_triangles





# -------- smoothed version of mesh ----------------

smooth = vtk.vtkSmoothPolyDataFilter()
smooth.SetNumberOfIterations(32) #standard value sused in old mrMesh
smooth.SetRelaxationFactor(0.5) #standard value sused in old mrMesh
smooth.FeatureEdgeSmoothingOff()
smooth.SetFeatureAngle(45)
smooth.SetEdgeAngle(15)
smooth.SetBoundarySmoothing(1)
smooth.SetInputConnection(normals.GetOutputPort())
smooth.Update()

# different smoothing option?
'''
smooth = vtk.vtkWindowedSincPolyDataFilter()
smooth.SetInputConnection(mc.GetOutputPort())
smooth.SetNumberOfIterations(30)
smooth.SetPassBand(0.5)
smooth.SetFeatureAngle(45)
smooth.SetEdgeAngle(15)
smooth.SetBoundarySmoothing(1)
smooth.SetFeatureEdgeSmoothing(0)
smooth.Update()
'''


# ---- Vertices - smoothed ---------------------
smooth_verts = smooth.GetOutput().GetPoints().GetData()
output_smooth_verts = array(numpy_support.vtk_to_numpy(smooth_verts).transpose(),'d')

if debug: print output_smooth_verts


# ---- Curvature ---------------------
curvature = vtk.vtkCurvatures()
curvature.SetInputConnection(smooth.GetOutputPort())
curvature.SetCurvatureTypeToMean()
curvature.Update()

curv = curvature.GetOutput().GetPointData().GetScalars()
output_curvature = array(numpy_support.vtk_to_numpy(curv).transpose(),'d')

if debug: print min(output_curvature)
if debug: print max(output_curvature)
if debug: print output_curvature



# -------- colours based on curvature ------------

# turn curvature into color
tmp_colors = output_curvature.copy()

#min_curv = min(tmp_colors)
#max_curv = max(tmp_colors)
#tmp_colors = (tmp_colors -min_curv) / (max_curv-min_curv) *255

tmp_colors[tmp_colors>=0] = 160 #standard value sused in old mrMesh
tmp_colors[tmp_colors<0] = 85 #standard value sused in old mrMesh

output_colors = vstack((tmp_colors, tmp_colors, tmp_colors, ones((1,len(tmp_colors)))*255))
output_colors = array(output_colors,'d')

if debug: print output_colors

# OK we have all the data we need now, lets write it out to file

data = {} #empty dictionary
data['initVertices'] = output_init_verts
data['initialvertices'] = output_init_verts
data['vertices'] = output_smooth_verts
data['colors'] = output_colors
data['normals'] = output_normals
data['triangles'] = output_triangles
data['curvature'] = output_curvature

# save it out
savemat(fileToSave,data)



# data have been sent, but let's view them here

pdm = vtk.vtkPolyDataMapper()
pdm.SetInputConnection(confilter.GetOutputPort())

actor = vtk.vtkActor()
actor.SetMapper(pdm)

ren = vtk.vtkRenderer()
renWin = vtk.vtkRenderWindow()
renWin.AddRenderer(ren)

iren = vtk.vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

ren.AddActor(actor)
ren.SetBackground(1,1,1)
renWin.SetSize(500,500)

iren.Initialize()
iren.Start()



pdm = vtk.vtkPolyDataMapper()
pdm.SetInputConnection(curvature.GetOutputPort())

actor = vtk.vtkActor()
actor.SetMapper(pdm)

ren = vtk.vtkRenderer()
renWin = vtk.vtkRenderWindow()
renWin.AddRenderer(ren)

iren = vtk.vtkRenderWindowInteractor()
iren.SetRenderWindow(renWin)

ren.AddActor(actor)
ren.SetBackground(1,1,1)
renWin.SetSize(500,500)

iren.Initialize()
iren.Start()

