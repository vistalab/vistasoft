/*
 *
 * To compile on most unices (maybe BSD/OS-X?):
 *   mex dtiLoadConTrackPaths.c
 *
 * On 32-bit Windows, try:
 *   mex -D_WINDOWS_ -I./win32 dtiLoadConTrackPaths.c
 * On 64-bit Windows, try:
 *   mex -D_WINDOWS_ -I./win64 dtiLoadConTrackPaths.c
 *
 * On Cygwin/gnumex, try:
 *   mex dtiLoadConTrackPaths.c
 *
 *
 * HISTORY:
 *
 * 2008.07.27: AJS wrote it.
 *
 */
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  const char *fnames[10];
  int i=0;
  int buflen;
  char* filename;
  const mwSize color_dims[]={2,2};
  char color_data[]={235,235,15};
  fnames[i++] = "name";
  fnames[i++] = "colorRgb";
  fnames[i++] = "thickness";
  fnames[i++] = "visible";
  fnames[i++] = "seeds";
  fnames[i++] = "seedRadius";
  fnames[i++] = "seedVoxelOffsets";
  fnames[i++] = "params";
  fnames[i++] = "fibers";
  fnames[i++] = "query_id";
  plhs[0] = mxCreateStructMatrix(1, 1, 10, fnames);

/*   if(nrhs==0&&nlhs==1){	 */
/*     /\* In this case, we return an empty nifti struct- Set some simple defaults *\/ */
/*     mxSetField(plhs[0], 0, "xyz_units", mxCreateString(getNiftiUnitStrOptions())); */
/*     mxSetField(plhs[0], 0, "time_units", mxCreateString(getNiftiUnitStrOptions())); */
/*     return; */
/*   } */
  if( nrhs!=1 || nlhs!=1 ){
      mexPrintf("fg = dtiLoadConTrackPaths(fileName)\n\n");
      mexPrintf("Loads the ConTrack PDB pathways and stores them in the mrDiffusion fiber group.\n");
      return;
  } 

  // Set the filename
  if(mxIsChar(prhs[0])!= 1)
    mexWarnMsgTxt("Input must be a filename.");
  /* allocate memory for input string */
  buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;
  filename = (char *)mxCalloc(buflen, sizeof(char));
  /* copy the string data from prhs[0] into a C string input_ buf. */
  if(mxGetString(prhs[0], filename, buflen))
    mexWarnMsgTxt("Not enough space. String is truncated.");
  mxSetField(plhs[0], 0, "name", mxCreateString(filename));

  // Sets the color field
/*   mxSetField(plhs[0], 0, "colorRgb", mxCreateNumericArray(1,color_dims,mxINT8_CLASS,mxREAL); */
}
