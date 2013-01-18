/*
 *
 * To compile on most unices (maybe BSD/OS-X?):
 *   mex readFileNifti.cpp nifti1_io.c znzlib.c
 *
 * On Windows, try:
 *   mex -D_WINDOWS_ -I./win32 readFileNifti.cpp nifti1_io.c znzlib.c ./win32/zlib.lib
 *
 * On Cygwin/gnumex, try:
 *   mex readFileNifti.cpp nifti1_io.c znzlib.c -I../../../VISTAPACK/zlib/include/cygwin ../../../VISTAPACK/zlib/lib/cygwin/libz.a
 */

#include <mex.h>
#include "nifti1_io.h"
#include "nifti_mex.h"

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
		int i;

    /* create a Matlab struct for output  */
		const char *fnames[40];
		i=0;
		fnames[i++] = "data";
		fnames[i++] = "fname";
		fnames[i++] = "ndim";
		fnames[i++] = "pixdim";      /* voxel size, in xyz_units */
		fnames[i++] = "scl_slope";
		fnames[i++] = "scl_inter";   /* scaling parameters */
		fnames[i++] = "cal_min";
		fnames[i++] = "cal_max";     /* calibration parameters */
		fnames[i++] = "qform_code";
		fnames[i++] = "sform_code";  /* codes for (x,y,z) space meaning */
		fnames[i++] = "freq_dim";
		fnames[i++] = "phase_dim";   /* indexes (1,2,3, or 0) for MRI */
		fnames[i++] = "slice_dim";   /* directions in dim[]/pixdim[]  */
		fnames[i++] = "slice_code";  /* code for slice timing pattern */
		fnames[i++] = "slice_start";
		fnames[i++] = "slice_end";   /* indexes for start & stop of slices */
		fnames[i++] = "slice_duration";/* time between individual slices */
		fnames[i++] = "quatern_b";
		fnames[i++] = "quatern_c";     /* quaternion transform parameters   */
		fnames[i++] = "quatern_d";
		fnames[i++] = "qoffset_x";     /* [when writing a dataset,  these ] */
		fnames[i++] = "qoffset_y";
		fnames[i++] = "qoffset_z";     /* [are used for qform, NOT qto_xyz] */
		fnames[i++] = "qfac";
		fnames[i++] = "qto_xyz";       /* (mat44) qform: transform (i,j,k) to (x,y,z) */
		fnames[i++] = "qto_ijk";       /* (mat44) qform: transform (x,y,z) to (i,j,k) */
		fnames[i++] = "sto_xyz";       /* (mat44) sform: transform (i,j,k) to (x,y,z) */
		fnames[i++] = "sto_ijk";       /* (mat44) sform: transform (x,y,z) to (i,j,k) */
		fnames[i++] = "toffset";                 /* time coordinate offset */
		fnames[i++] = "xyz_units";
		fnames[i++] = "time_units";    /* dx,dy,dz & dt units: NIFTI_UNITS_* code */
		fnames[i++] = "nifti_type";    /* 0==ANALYZE, 2==NIFTI-1 (2 files), 1==NIFTI-1 (1 file),3==NIFTI-ASCII */
		fnames[i++] = "intent_code";   /* statistic type (or something) */
		fnames[i++] = "intent_p1";
		fnames[i++] = "intent_p2";     /* intent parameters */
		fnames[i++] = "intent_p3";
		fnames[i++] = "intent_name";   /* char[16] */
		fnames[i++] = "descrip";       /* char[80] */
		fnames[i++] = "aux_file";      /* char[24] */
		fnames[i++] = "num_ext";
    plhs[0] = mxCreateStructMatrix(1, 1, 40, fnames);

    if(nrhs!=1){
			
			if(nlhs==0){
			  mexPrintf("\nniftiImage = readFileNifti(fileName)\n\n");
			mexPrintf("Reads a NIFTI image and populates a structure that should resemble\n");
			mexPrintf("the NIFTI 1 standard (see http://nifti.nimh.nih.gov/nifti-1/ ).\n\n");
				mexPrintf("Call this function again with an output argument to get an empty structure.\n\n");
				plhs[0] = NULL;
			}else{
				// Set some simple defaults
				mxSetField(plhs[0], 0, "xyz_units", mxCreateString(getNiftiUnitStr()));
				mxSetField(plhs[0], 0, "time_units", mxCreateString(getNiftiUnitStr()));
			}
			return;
    }else if(nlhs>1) mexErrMsgTxt("Too many output arguments");

    /* The first arg must be a string (row-vector char). */
    if(mxIsChar(prhs[0])!= 1)
      myErrMsg("Input must be a string.");
    if(mxGetM(prhs[0])!=1)
      myErrMsg("Input must be a row vector.");
    
    /* allocate memory for input string */
    int buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0])) + 1;
    char *inFileName = (char *)mxCalloc(buflen, sizeof(char));

    /* copy the string data from prhs[0] into a C string input_ buf. */
    if(mxGetString(prhs[0], inFileName, buflen))
      mexWarnMsgTxt("Not enough space. String is truncated.");
    
    /* Load the nifti image */
		nifti_image *nim;
		nim = nifti_image_read(inFileName, 1);
		if(nim == NULL) myErrMsg("nim is NULL!");

		/* 
		 * Push NIFTI format into a matlab struct.
		 */

    int dims[7];
		for(i=0; i<7; i++) dims[i] = nim->dim[i+1];

		/* *** TO DO: support all the possible types. */
		mxClassID dt; mxComplexity cmp = mxREAL;
		switch(nim->datatype){
		case DT_UINT8: dt=mxUINT8_CLASS; break;
		case DT_INT8: dt=mxINT8_CLASS; break;
		case DT_UINT16: dt=mxUINT16_CLASS; break;
		case DT_INT16: dt=mxINT16_CLASS; break;
		case DT_UINT32: dt=mxUINT32_CLASS; break;
		case DT_INT32: dt=mxINT32_CLASS; break;
		case DT_UINT64: dt=mxUINT64_CLASS; break;
		case DT_INT64: dt=mxINT64_CLASS; break;
		case DT_FLOAT32: dt=mxSINGLE_CLASS; break;
		case DT_FLOAT64: dt=mxDOUBLE_CLASS; break;
		case DT_COMPLEX64: dt=mxSINGLE_CLASS; cmp=mxCOMPLEX; break;
		case DT_COMPLEX128: dt=mxDOUBLE_CLASS; cmp=mxCOMPLEX; break;
		case DT_RGB24: dt=mxUINT8_CLASS; break;
		default: mexErrMsgTxt("Unknown data type!");
		}

		/* 
		 * *** TO DO:
		 * We copy the NIFTI data to the matlab array. This is much safer
		 * than trying to pass the nim pointer back, since the nifti routine  
		 * didn't use mxMalloc. It would be more efficient if we could 
		 * allocate the memory block ourselves and tell the nifti lib routine
		 * to put it there.
		 */
		mxArray *tmp = mxCreateNumericArray(nim->ndim, dims, dt, cmp);
		/* I assume that we can rely on the nifti routine to byte-swap for us? */
		memcpy(mxGetData(tmp), nim->data, nim->nbyper*nim->nvox);
	  free(nim->data);
    mxSetField(plhs[0], 0, "data", tmp);
		mxSetField(plhs[0], 0, "fname", mxCreateString(nim->fname));
		mxSetField(plhs[0], 0, "ndim", mxCreateDoubleScalar(nim->ndim));
		mxSetField(plhs[0], 0, "datatype", mxCreateDoubleScalar(nim->datatype));
		mxArray *pd = mxCreateDoubleMatrix(1,nim->ndim,mxREAL);
		double *pdPtr = (double *)mxGetData(pd);
		for(i=0; i<nim->ndim; i++) pdPtr[i] = (double)nim->pixdim[i+1];
		mxSetField(plhs[0], 0, "pixdim", pd);
		mxSetField(plhs[0], 0, "scl_slope", mxCreateDoubleScalar(nim->scl_slope));
		mxSetField(plhs[0], 0, "scl_inter", mxCreateDoubleScalar(nim->scl_inter));
		mxSetField(plhs[0], 0, "cal_min", mxCreateDoubleScalar(nim->cal_min));
		mxSetField(plhs[0], 0, "cal_max", mxCreateDoubleScalar(nim->cal_max));
		mxSetField(plhs[0], 0, "qform_code", mxCreateDoubleScalar(nim->qform_code));
		mxSetField(plhs[0], 0, "sform_code", mxCreateDoubleScalar(nim->sform_code));
		mxSetField(plhs[0], 0, "freq_dim", mxCreateDoubleScalar(nim->freq_dim));
		mxSetField(plhs[0], 0, "phase_dim", mxCreateDoubleScalar(nim->phase_dim));
		mxSetField(plhs[0], 0, "slice_dim", mxCreateDoubleScalar(nim->slice_dim));
		mxSetField(plhs[0], 0, "slice_code", mxCreateDoubleScalar(nim->slice_code));
		mxSetField(plhs[0], 0, "slice_start", mxCreateDoubleScalar(nim->slice_start));
		mxSetField(plhs[0], 0, "slice_end", mxCreateDoubleScalar(nim->slice_end));
		mxSetField(plhs[0], 0, "slice_duration", mxCreateDoubleScalar(nim->slice_duration));
		mxSetField(plhs[0], 0, "quatern_b", mxCreateDoubleScalar(nim->quatern_b));
		mxSetField(plhs[0], 0, "quatern_c", mxCreateDoubleScalar(nim->quatern_c));
		mxSetField(plhs[0], 0, "quatern_d", mxCreateDoubleScalar(nim->quatern_d));
		mxSetField(plhs[0], 0, "qoffset_x", mxCreateDoubleScalar(nim->qoffset_x));
		mxSetField(plhs[0], 0, "qoffset_y", mxCreateDoubleScalar(nim->qoffset_y));
		mxSetField(plhs[0], 0, "qoffset_z", mxCreateDoubleScalar(nim->qoffset_z));
		mxSetField(plhs[0], 0, "qfac", mxCreateDoubleScalar(nim->qfac));
		mxArray *qx = mxCreateDoubleMatrix(4,4,mxREAL);
		double *qxPtr = (double *)mxGetData(qx);
		/* Do matlab and C assume the same row,column order? */
		for(i=0; i<16; i++) qxPtr[i] = (double)nim->qto_xyz.m[i%4][i/4];
		mxSetField(plhs[0], 0, "qto_xyz", qx);
		mxArray *qi = mxCreateDoubleMatrix(4,4,mxREAL);
		double *qiPtr = (double *)mxGetData(qi);
		for(i=0; i<16; i++) qiPtr[i] = (double)nim->qto_ijk.m[i%4][i/4];
		mxSetField(plhs[0], 0, "qto_ijk", qi);
		mxArray *sx = mxCreateDoubleMatrix(4,4,mxREAL);
		double *sxPtr = (double *)mxGetData(sx);
		for(i=0; i<16; i++) sxPtr[i] = (double)nim->sto_xyz.m[i%4][i/4];
		mxSetField(plhs[0], 0, "sto_xyz", sx);
		mxArray *si = mxCreateDoubleMatrix(4,4,mxREAL);
		double *siPtr = (double *)mxGetData(si);
		for(i=0; i<16; i++) siPtr[i] = (double)nim->sto_ijk.m[i%4][i/4];
		mxSetField(plhs[0], 0, "sto_ijk", si);
		mxSetField(plhs[0], 0, "toffset", mxCreateDoubleScalar(nim->toffset));
		mxSetField(plhs[0], 0, "xyz_units", mxCreateString(getNiftiUnitStr(nim->xyz_units)));
		mxSetField(plhs[0], 0, "time_units", mxCreateString(getNiftiUnitStr(nim->time_units)));
		mxSetField(plhs[0], 0, "nifti_type", mxCreateDoubleScalar(nim->nifti_type));
		mxSetField(plhs[0], 0, "intent_code", mxCreateDoubleScalar(nim->intent_code));
		mxSetField(plhs[0], 0, "intent_p1", mxCreateDoubleScalar(nim->intent_p1));
		mxSetField(plhs[0], 0, "intent_p2", mxCreateDoubleScalar(nim->intent_p2));
		mxSetField(plhs[0], 0, "intent_p3", mxCreateDoubleScalar(nim->intent_p3));
		mxSetField(plhs[0], 0, "intent_name", mxCreateString(nim->intent_name));
		mxSetField(plhs[0], 0, "descrip", mxCreateString(nim->descrip));
		mxSetField(plhs[0], 0, "aux_file", mxCreateString(nim->aux_file));
		mxSetField(plhs[0], 0, "num_ext", mxCreateDoubleScalar(nim->num_ext));
		// *** TO DO: support extended header fileds!
}
