/****************************************************
 *
 * vtkPolyDataRenderer
 *
 * A simple vtkPolyData (ie. mesh) viewer.
 *
 * This code started with an example provided by Dominik Szczerba <domi at vision ee ethz ch>.
 * I added the pthreads code and persistent data to allow the interactive visualization window 
 * to stay open after the mex file finishes. This way, you can open a mesh and then continue
 * to use matlab. You can also update the mesh in the existing visualization window (e.g., change 
 * the vertex colors).
 *
 * The code is incomplete. It crashes matlab hard if you try to close the window or clear mex.
 * I also started to add support for opening multiple visualization windows (each running in
 * its own thread), but this is incomplete and not really working.
 *
 *
 * To compile, first be sure to install the VTK development files. E.g., on Fedora, try:
 * sudo yum install vtk-devel
 *
 *
 * Then, try one of these mex commands (specifics depend on exactly where your VTK files end up).
 *
 *   mex -O -I/usr/include/vtk/ vtkPolyDataRenderer.cpp -L/usr/lib64/ -lvtkFiltering -lvtkRendering -lvtkCommon
 *
 * OR
 *
 *   mex -O -I/usr/include/vtk/ vtkPolyDataRenderer.cpp -L/usr/lib64/ -lvtkFiltering -lvtkRendering -lvtkCommon
 *
 *
 * Sample code:
 *
[x y z v] = flow;
q = z./x.*y.^3;
mesh=isosurface(x, y, z, q, -.08, v);
[N,M]=size(mesh.faces);
scalars=[0:1:N-1]'/(N-1);
vtkPolyDataRenderer(mesh.vertices',mesh.faces'-1,scalars')

% OR
load('/biac1/wandell/data/anatomy/dougherty/bothSmooth.mat');
c = uint8(msh.colors);
curWinNum = vtkPolyDataRenderer(msh.vertices,msh.triangles,c);

% To update the colors on an existing mesh:
c(3,:) = 127;
vtkPolyDataRenderer([],[],c)

 *
 *****************************************************/

#include <pthread.h>
#include <cstdlib>
#include <cmath>

/* MEX HEADERS */
#include <mex.h>

/* VTK HEADERS */
#include <vtkToolkits.h> /* Build-configured stuff, like VTK_USE_X */
#include <vtkPolyData.h>
#include <vtkPoints.h>
#include <vtkPointData.h>
#include <vtkCellArray.h>
#include <vtkDoubleArray.h>
#include <vtkPolyData.h>

#include <vtkCell.h>
#include <vtkCellData.h>
#include <vtkDataSet.h>
#include <vtkDataSetAttributes.h>
#include <vtkProperty.h>

#include <vtkDataSetMapper.h>
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkRenderer.h>
#include <vtkRenderWindow.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkInteractorStyleTrackballCamera.h>
#include <vtkCommand.h>
#include <vtkCamera.h>

// Put platform-specific thread handling code here:
#if defined(VTK_USE_X)

#elif defined(VTK_USE_CARBON)

#else

#endif


#define VERSION "Version 0.1 2008.03.05"

#define MAX_NUM_WINDOWS  32

typedef struct{
    pthread_t thread;  /* thread maintaining scene interaction */
    vtkPolyData *surf; /* surface rendered in the scene */
    unsigned int nVertices;
    unsigned int nFaces;
} sceneWindow;

/* 
 * GLOBAL VARIABLES 
 *
 * The values of these vars are preserved between calls to the mex function.
 * They are only cleared when Matlab exits or tries to explictly clear the
 * mex function (e.g., the user calls 'clear mex').
 */
sceneWindow gSceneWindows[MAX_NUM_WINDOWS];
int gCurWinNum;
unsigned long mex_call_counter=0;  /* Counter that counts how many calls made to this function */

/***********************************************************************/
void printStartMessage(){
  mexPrintf("\n===============================================================================\n"
	      "Loaded vtkRender MEX-file Compiled @ "
	      __DATE__ " " __TIME__  "\n"
	      VERSION "\n"
	      "Copyright (C) Bob Dougherty\n"
	      "GNU General Public License.\n\n"
	      "   http://sirl.stanford.edu/ \n\n"
	      "===============================================================================\n\n"
	      );
}

// VTK callback for interaction with the VTK event loop
class vtkMyCallback : public vtkCommand
{
public:
  static vtkMyCallback *New() 
    { return new vtkMyCallback; }
  virtual void Execute(vtkObject *caller, unsigned long, void*)
    {
      vtkRenderWindow *renwin = reinterpret_cast<vtkRenderWindow*>(caller);
      mexPrintf("%d\n",gCurWinNum);
      //mexPrintf("CameraPosition=[%0.1f, %0.1f, %0.1f]\n",renwin->GetActiveCamera()->GetPosition()[0],
      //          renderer->GetActiveCamera()->GetPosition()[1], renderer->GetActiveCamera()->GetPosition()[2]);
    }
};

void *renderWin (void *s){
  vtkPolyData *surf = (vtkPolyData *)s;

  // now render
  vtkDataSetMapper::SetResolveCoincidentTopologyToPolygonOffset();
  vtkPolyDataMapper *surfMapper = vtkPolyDataMapper::New();
  vtkActor *surfActor = vtkActor::New();
  vtkRenderer *aRenderer = vtkRenderer::New();
  vtkRenderWindow *renWin = vtkRenderWindow::New();
  vtkRenderWindowInteractor *iren = vtkRenderWindowInteractor::New();
  
  surfMapper->SetInput(surf);
  //surfMapper->ScalarVisibilityOff();
  //surfMapper->ScalarVisibilityOn();
  //surfMapper->SetScalarRange(0,1);
  // This should cause unsigned char 'scalars' to be treated as colors rather than LUT indices:
  // http://www.vtk.org/doc/release/5.0/html/a01699.html
  surfMapper->vtkMapper::SetColorModeToDefault();

  surfActor->SetMapper(surfMapper);
  surfActor->GetProperty()->SetAmbient(0.1);
  surfActor->GetProperty()->SetDiffuse(0.3);
  surfActor->GetProperty()->SetSpecular(0.5);
  surfActor->GetProperty()->SetSpecularPower(40.0);
  surfActor->GetProperty()->SetInterpolationToPhong(); // Flat, Gouraud, Phong
  
  aRenderer->AddActor(surfActor);
  aRenderer->SetBackground(1.0,1.0,1.0);
  //aRenderer->TwoSidedLightingOff();
  
  iren->SetRenderWindow(renWin);
  
  renWin->AddRenderer(aRenderer);
  renWin->SetSize(500,500);
  renWin->PointSmoothingOn();
  renWin->LineSmoothingOn();
  renWin->PolygonSmoothingOn();
  char title[64];
  sprintf(title, "mrMesh %02d",gCurWinNum);
  renWin->SetWindowInfo(title);

  vtkMyCallback *mo1 = vtkMyCallback::New();
  renWin->AddObserver(vtkCommand::StartEvent,mo1);
  mo1->Delete();

  renWin->Render();
  
  vtkInteractorStyleTrackballCamera *style = 
 	 vtkInteractorStyleTrackballCamera::New();
  iren->SetInteractorStyle(style);

  // Start interactive rendering
  iren->Initialize();
  iren->Start();

  // clean up
  if(surfMapper) surfMapper->Delete();
  if(surfActor)  surfActor->Delete();
  if(aRenderer)  aRenderer->Delete();
  if(surf)       surf->Delete();
  if(renWin)     renWin->Delete();
  if(iren)       iren->Delete();
  if(style)      style->Delete();

  return (NULL);
}

/****************************************************************************
 * This function is called when Matlab tries to unload this mex function. 
 */
void CleanUpMex(void)
{
   mexWarnMsgTxt("Unloading mex file.");
   /* Do something here. Maybe close down all active threads? */
}


/* MAIN FUNCTION */
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){

  double *v;	// Vertices
  double *f;	// Faces
  unsigned int i, j, nColors;

  /* Initialization on first call to the mex file */
  if(mex_call_counter==0){
    printStartMessage();
    mexAtExit(CleanUpMex);
    gCurWinNum = -1;
  }
  mex_call_counter++;

  if(nrhs<2) mexErrMsgTxt("2+ input args required");

  unsigned char* dcolors = 0;
  vtkUnsignedCharArray* dcolarr = 0;
  
  if(!mxIsEmpty(prhs[0])){
    gCurWinNum++;
    gSceneWindows[gCurWinNum].nVertices = mxGetN(prhs[0]);
    gSceneWindows[gCurWinNum].nFaces = mxGetN(prhs[1]);
    nColors = 0;
    v = (double*)mxGetPr(prhs[0]);
    f = (double*)mxGetPr(prhs[1]);
    // Initialize vtk variables
    gSceneWindows[gCurWinNum].surf = vtkPolyData::New();
    vtkPoints *sverts = vtkPoints::New();
    vtkCellArray *sfaces = vtkCellArray::New();

    // Load the point, cell, and data attributes.
    sverts->SetNumberOfPoints(gSceneWindows[gCurWinNum].nVertices);
    for(i=0; i<gSceneWindows[gCurWinNum].nVertices; i++){
      sverts->SetPoint(i,v);
      v+=3;
    }
    sfaces->Allocate(sfaces->EstimateSize(gSceneWindows[gCurWinNum].nFaces,3));
    for(i=0; i<gSceneWindows[gCurWinNum].nFaces; i++){
      // vtkIdType is an int, so we'd need to force f to be an int* for this faster code to work:
      //sfaces->InsertNextCell(3,(vtkIdType*)f);
      //f+=3;
      sfaces->InsertNextCell(3);
      sfaces->InsertCellPoint(vtkIdType(*f++));
      sfaces->InsertCellPoint(vtkIdType(*f++));
      sfaces->InsertCellPoint(vtkIdType(*f++));
    }
  
    // assign the pieces to the vtkPolyData.
    gSceneWindows[gCurWinNum].surf->SetPoints(sverts);
    gSceneWindows[gCurWinNum].surf->SetPolys(sfaces);
    sverts->Delete();
    sfaces->Delete();
    mexPrintf("got %d nodes, %d faces\n", gSceneWindows[gCurWinNum].nVertices, gSceneWindows[gCurWinNum].nFaces);
  }else if(nrhs<3 || mxIsEmpty(prhs[2])){
    // Nothing passed in
    if(gCurWinNum>=0){
      mexPrintf("Terminating window %d (%d)\n", gCurWinNum, gSceneWindows[gCurWinNum].thread);
      pthread_cancel(gSceneWindows[gCurWinNum].thread);
      return;
    }
  }

  if(nrhs>=3){
    nColors = mxGetN(prhs[2]);
    mexPrintf("setting %d colors in window %d.\n",nColors,gCurWinNum);
    if(nColors!=gSceneWindows[gCurWinNum].nFaces && nColors!=gSceneWindows[gCurWinNum].nVertices)
      mexErrMsgTxt("dimension mismatch in color array");
    dcolors = (unsigned char *)mxGetPr(prhs[2]);
    dcolarr = vtkUnsignedCharArray::New();
    dcolarr->SetNumberOfComponents(4);
    dcolarr->SetNumberOfTuples(nColors);
    dcolarr->SetName("aCellScalar");
    for(i=0; i<nColors; i++){
      dcolarr->SetTupleValue(i,dcolors);
      dcolors+=4;
    }
  }

  // We can either color triangle faces or vertices
  if(nColors==gSceneWindows[gCurWinNum].nFaces)
    gSceneWindows[gCurWinNum].surf->GetCellData()->SetScalars(dcolarr);
  else if(nColors==gSceneWindows[gCurWinNum].nVertices)
    gSceneWindows[gCurWinNum].surf->GetPointData()->SetScalars(dcolarr);
  
  if(!mxIsEmpty(prhs[0])){
    int stat = pthread_create(&gSceneWindows[gCurWinNum].thread, NULL, renderWin, gSceneWindows[gCurWinNum].surf);
    mexPrintf("New threadID: %d\n",gSceneWindows[gCurWinNum].thread);
    if(stat){
      mexPrintf("Return code from pthread_create() is %d\n", stat);
      mexErrMsgTxt("ERROR.");
    }
  }
  plhs[0] = mxCreateDoubleScalar((double)gCurWinNum);
}

