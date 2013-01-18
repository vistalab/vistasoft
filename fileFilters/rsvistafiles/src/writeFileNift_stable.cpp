/*
 *
 * To compile on most unices (maybe BSD/OS-X?):
 *   mex writeFileNifti.cpp nifti1_io.c znzlib.c
 *
 * On Windows (Visual Studio), try:
 *   mex -D_WINDOWS_ -I./win32 writeFileNifti.cpp nifti1_io.c znzlib.c ./win32/zlib.lib
 * 
 * On Cygwin/gnumex, try:
 *   mex writeFileNifti.cpp nifti1_io.c znzlib.c -I../../../VISTAPACK/zlib/include/cygwin ../../../VISTAPACK/zlib/lib/cygwin/libz.a
 */

#include <mex.h>
#include "nifti1_io.h"
#include "nifti_mex.h"


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
		int i;

    if(nrhs!=1){
			mexPrintf("\nwriteFileNifti(niftiStruct)\n\n");
			mexPrintf("Writes a NIFTI image based on fields of a structure that resembles\n");
			mexPrintf("the NIFTI 1 standard (see http://nifti.nimh.nih.gov/nifti-1/ ).\n");
 		  mexPrintf("See readFileNifti for details about the expected niftiStruct.\n\n");
			return;
    }else if(nlhs>0) { mexPrintf("Too many output arguments"); return; }

    /* The first arg must be a nifti struct. */
		if(!mxIsStruct(prhs[0])) mexErrMsgTxt("First arg must be a nifti struct.");
    const mxArray *mxnim = prhs[0];
		// Sanity check that this is a complete NIFTI struct
		if(mxGetField(mxnim,0,"fname")==NULL || mxGetField(mxnim,0,"data")==NULL)
			myErrMsg("First argument must be a proper NIFTI struct (see readFileNifti).\n\n");

    /* Create an empty NIFTI C struct */
		nifti_image *nim = (nifti_image *)mxCalloc(1, sizeof(nifti_image));
		if(!nim) myErrMsg("failed to allocate nifti image");

		nim->nifti_type = 1; // We only support single-file NIFTI format

		/* Load the C-struct with fields from the matlab struct */
		mxArray *fname =  mxGetField(mxnim,0,"fname");
		mxArray *data = mxGetField(mxnim,0,"data");
    // fname field needs to be allocated
    int buflen = (mxGetN(fname)) + 1;
    nim->fname = (char *)mxCalloc(buflen, sizeof(char));
    if(mxGetString(fname, nim->fname, buflen))
      mexWarnMsgTxt("Not enough space- fname string is truncated.");
		nim->iname = NULL;
		nim->data = mxGetData(data); 
		nim->ndim = mxGetNumberOfDimensions(data);
		nim->dim[0] = nim->ndim;
		const int *dims = mxGetDimensions(data);
		for(i=0; i<nim->ndim; i++) nim->dim[i+1] = dims[i];
		for(i=nim->ndim+1; i<8; i++) nim->dim[i] = 1;
		// Why do I have to assign these explicitly? 
		nim->nx = nim->dim[1];
		nim->ny = nim->dim[2];
		nim->nz = nim->dim[3];
		nim->nt = nim->dim[4];
		nim->nu = nim->dim[5];
		nim->nv = nim->dim[6];
		nim->nw = nim->dim[7];
		//for(i=0; i<8; i++) mexPrintf("%d ",nim->dim[i]); mexPrintf("\n\n");

		nim->nvox = mxGetNumberOfElements(data);
		// *** TO DO: we should support DT_RGB24 type (triplet of uint8)
		if(mxIsComplex(data)){
			switch(mxGetClassID(data)){
			case mxSINGLE_CLASS: nim->datatype=DT_COMPLEX64; nim->nbyper=8; break;
			case mxDOUBLE_CLASS: nim->datatype=DT_COMPLEX128; nim->nbyper=16; break;
			default: myErrMsg("Unknown data type!");
			}
		}else{
			switch(mxGetClassID(data)){
			case mxUINT8_CLASS: nim->datatype=DT_UINT8; nim->nbyper=1; break;
			case mxINT8_CLASS: nim->datatype=DT_INT8; nim->nbyper=1; break;
			case mxUINT16_CLASS: nim->datatype=DT_UINT16; nim->nbyper=2; break;
			case mxINT16_CLASS: nim->datatype=DT_INT16; nim->nbyper=2; break;
			case mxUINT32_CLASS: nim->datatype=DT_UINT32; nim->nbyper=4; break;
			case mxINT32_CLASS: nim->datatype=DT_INT32; nim->nbyper=4; break;
			case mxUINT64_CLASS: nim->datatype=DT_UINT64; nim->nbyper=8; break;
			case mxINT64_CLASS: nim->datatype=DT_INT64; nim->nbyper=8; break;
			case mxSINGLE_CLASS: nim->datatype=DT_FLOAT32; nim->nbyper=4; break;
			case mxDOUBLE_CLASS: nim->datatype=DT_FLOAT64; nim->nbyper=8; break;
			default: mexErrMsgTxt("Unknown data type!");
			}
		}

		double *pdPtr = (double *)mxGetData(mxGetField(mxnim,0,"pixdim"));
		int nPixDim = mxGetM(mxGetField(mxnim,0,"pixdim"))*mxGetN(mxGetField(mxnim,0,"pixdim"));
		if(nPixDim>8) nPixDim=8;
		for(i=0; i<nPixDim; i++) nim->pixdim[i+1] = (float)pdPtr[i];
		// xxx dla fixed bug below (i was not being assigned).
		//  for(nPixDim+1; i<8; i++) nim->pixdim[i] = (float)1.0;
		for(i = nPixDim+1; i<8; i++) nim->pixdim[i] = (float)1.0;
		nim->dx = nim->pixdim[1]; 
		nim->dy = nim->pixdim[2];
		nim->dz = nim->pixdim[3];
		nim->dt = nim->pixdim[4];
		nim->du = nim->pixdim[5];
		nim->dv = nim->pixdim[6];
		nim->dw = nim->pixdim[7];

		nim->scl_slope = mxGetScalar(mxGetField(mxnim,0,"scl_slope"));
		nim->scl_inter = mxGetScalar(mxGetField(mxnim,0,"scl_inter"));
		nim->cal_min = mxGetScalar(mxGetField(mxnim,0,"cal_min"));
		nim->cal_max = mxGetScalar(mxGetField(mxnim,0,"cal_max"));
		nim->qform_code = (int)mxGetScalar(mxGetField(mxnim,0,"qform_code"));
		nim->sform_code = (int)mxGetScalar(mxGetField(mxnim,0,"sform_code"));
		nim->freq_dim = (int)mxGetScalar(mxGetField(mxnim,0,"freq_dim"));
		nim->phase_dim = (int)mxGetScalar(mxGetField(mxnim,0,"phase_dim"));
		nim->slice_dim = (int)mxGetScalar(mxGetField(mxnim,0,"slice_dim"));
		nim->slice_code = (int)mxGetScalar(mxGetField(mxnim,0,"slice_code"));
		nim->slice_start = (int)mxGetScalar(mxGetField(mxnim,0,"slice_start"));
		nim->slice_end = (int)mxGetScalar(mxGetField(mxnim,0,"slice_end"));
		nim->slice_duration = mxGetScalar(mxGetField(mxnim,0,"slice_duration"));
    /* if qform_code > 0, the quatern_*, qoffset_*, and qfac fields determine
     * the qform output, NOT the qto_xyz matrix; if you want to compute these
     * fields from the qto_xyz matrix, you can use the utility function
     * nifti_mat44_to_quatern() */
		nim->quatern_b = mxGetScalar(mxGetField(mxnim,0,"quatern_b"));
		nim->quatern_c = mxGetScalar(mxGetField(mxnim,0,"quatern_c"));
		nim->quatern_d = mxGetScalar(mxGetField(mxnim,0,"quatern_d"));
		nim->qoffset_x = mxGetScalar(mxGetField(mxnim,0,"qoffset_x"));
		nim->qoffset_y = mxGetScalar(mxGetField(mxnim,0,"qoffset_y"));
		nim->qoffset_z = mxGetScalar(mxGetField(mxnim,0,"qoffset_z"));
		nim->qfac = mxGetScalar(mxGetField(mxnim,0,"qfac"));
		nim->pixdim[0] = nim->qfac; // pixdim[0] is the same as qfac (again- why duplicate the field?)

		double *sxPtr = (double *)mxGetData(mxGetField(mxnim,0,"sto_xyz"));
		for(i=0; i<16; i++) nim->sto_xyz.m[i%4][i/4] = (float)sxPtr[i];

		nim->toffset = mxGetScalar(mxGetField(mxnim,0,"toffset"));
		// Allow units to be specified as a string
		char str[16]; 
		mxGetString(mxGetField(mxnim,0,"xyz_units"),str,16);
		nim->xyz_units = getNiftiUnitCode(str);
		mxGetString(mxGetField(mxnim,0,"time_units"),str,16);
		nim->time_units = getNiftiUnitCode(str);
		nim->intent_code = (int)mxGetScalar(mxGetField(mxnim,0,"intent_code"));
		nim->intent_p1 = mxGetScalar(mxGetField(mxnim,0,"intent_p1"));
		nim->intent_p2 = mxGetScalar(mxGetField(mxnim,0,"intent_p2"));
		nim->intent_p3 = mxGetScalar(mxGetField(mxnim,0,"intent_p3"));
		mxGetString(mxGetField(mxnim,0,"intent_name"), nim->intent_name, 16);
		mxGetString(mxGetField(mxnim,0,"descrip"), nim->descrip, 80);
		mxGetString(mxGetField(mxnim,0,"aux_file"), nim->aux_file, 24);
		// *** TO DO: support extended header fileds!
		nim->num_ext = 0;

		/* I assume that we can rely on the nifti routine to byte-swap for us? */
		nifti_image_write(nim);
}
