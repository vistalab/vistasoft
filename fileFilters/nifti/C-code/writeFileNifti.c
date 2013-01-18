/*
 * Simple Matlab mex wrapper for NIFTI-1 reference code.
 *
 * To compile, try:
 *   mex writeFileNifti.c nifti1_io.c znzlib.c zlib/adler32.c zlib/compress.c zlib/crc32.c zlib/deflate.c zlib/gzio.c zlib/infback.c zlib/inffast.c zlib/inflate.c zlib/inftrees.c zlib/trees.c zlib/zutil.c
 * On 32-bit Windows, try:
 *     mex -D_WINDOWS_ -I./win32 writeFileNifti.c nifti1_io.c znzlib.c ./win32/zlib.lib
 *   On 64-bit Windows, try:
 *     mex -D_WINDOWS_ -I./win64 writeFileNifti.c nifti1_io.c znzlib.c ./win64/zlib.lib
 *
 * See readFileNifti for more compile info.
 *
 * HISTORY:
 *
 * Sometime in 2006? Bob Dougherty (bobd@stanford.edu) wrote it.
 *
 * 2007.07.18 RFD: changed the code so that the passed qto/sto transforms are
 * one-indexed rather than zero-indexed. With this change, the qto/sto transforms
 * now map to and from Matlab's one-indexed voxel volume rather than the zero-indexed
 * volume of the NIFTI spec. This allows us to keep the data on disk in the
 * NIFTI-compliant zero-indexed form while allowing convenient transforms for
 * our one-indexed Matlab world.
 *
 * 2009.03.24 RFD: update nifti reference code to latest and added support for RGB data.
 *
 * 2009.09.24 RFD: fixed qto X-origin off-by-one error with left-right flipped data (ie. qfac<0). 
 *
 * 2010.01.26 RFD: copied zlib code source code so that we can build zlib 
 * functions directly rather than trying to include a zlib library. This
 * makes compiling easier, especially when the matlab and system zlib 
 * versions are very different. 
 *
 */

#include <mex.h>
#include "nifti1_io.h"
#include "nifti_mex.h"


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
    int i;
    const mxArray *mxnim;
    int buflen;
    nifti_image *nim;
    mxArray *fname;
    mxArray *data;
    const int *dims;
    double *pdPtr;
    double *dimPtr;
    int nPixDim;
    double *sxPtr;
    char str[16];
    
    if(nrhs!=1){
        mexPrintf("\nwriteFileNifti(niftiStruct)\n\n");
        mexPrintf("Writes a NIFTI image based on fields of a structure that resembles\n");
        mexPrintf("the NIFTI 1 standard (see http://nifti.nimh.nih.gov/nifti-1/ ).\n");
        mexPrintf("Note that this function ignores the quatern params that are passed in\n");
        mexPrintf("and instead computes them from the qto_xyz that is passed in.\n");
        mexPrintf("See readFileNifti for details about the expected niftiStruct.\n\n");
        return;
    }else if(nlhs>0) { mexPrintf("Too many output arguments"); return; }
    
    /* The first arg must be a nifti struct. */
    if(!mxIsStruct(prhs[0])) mexErrMsgTxt("First arg must be a nifti struct.");
    mxnim = prhs[0];
    /* Sanity check that this is a complete NIFTI struct */
    if(mxGetField(mxnim,0,"fname")==NULL || mxGetField(mxnim,0,"data")==NULL)
        myErrMsg("First argument must be a proper NIFTI struct (see readFileNifti).\n\n");
    
    /* Create an empty NIFTI C struct */
    nim = (nifti_image *)mxCalloc(1, sizeof(nifti_image));
    if(!nim) myErrMsg("failed to allocate nifti image");
    
    nim->nifti_type = 1; /* We only support single-file NIFTI format */
    
        /* Load the C-struct with fields from the matlab struct */
    fname =  mxGetField(mxnim,0,"fname");
    data = mxGetField(mxnim,0,"data");
    /* fname field needs to be allocated */
    buflen = (int)(mxGetN(fname)) + 1;
    nim->fname = (char *)mxCalloc(buflen, sizeof(char));
    if(mxGetString(fname, nim->fname, buflen))
        mexWarnMsgTxt("Not enough space- fname string is truncated.");
    nim->iname = NULL;
    nim->data = mxGetData(data);
    nim->ndim = mxGetNumberOfDimensions(data);
    nim->dim[0] = nim->ndim;
    dims = mxGetDimensions(data);
    
    nim->nvox = (int)mxGetNumberOfElements(data);

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
    dimPtr = (double *)mxGetData(mxGetField(mxnim,0,"dim"));
    /* check to see if the data look like rgb or rgba types */
    /* *** WORK HERE: trying to save RGB/RGBA causes a segfault in nifti_image_write(nim); */
    if(dimPtr[0]*3==dims[0] && nim->nbyper==1){
        mexPrintf("Assuming that data are RGB\n");
        nim->datatype = DT_RGB24;
        nim->nbyper = 3;
        nim->dim[1] = dimPtr[0];
    }else if(dimPtr[0]*4==dims[0] && nim->nbyper==1){
        mexPrintf("Assuming that data are RGBA\n");
        nim->datatype = DT_RGBA32;
        nim->nbyper = 4;
        nim->dim[1] = dimPtr[0];
    }else nim->dim[1] = dims[0];
    for(i=1; i<nim->ndim; i++) nim->dim[i+1] = dims[i];
    
    for(i=nim->ndim+1; i<8; i++) nim->dim[i] = 1;
    
    nim->nx = nim->dim[1];
    nim->ny = nim->dim[2];
    nim->nz = nim->dim[3];
    nim->nt = nim->dim[4];
    nim->nu = nim->dim[5];
    nim->nv = nim->dim[6];
    nim->nw = nim->dim[7];
    /*mexPrintf("ndim=%d,nbyteper=%d, nim->dim[1]=%d,nim->dim[2]=%d,nim->dim[3]=%d,nim->dim[4]=%d\n",nim->ndim,nim->nbyper,nim->dim[1],nim->dim[2],nim->dim[3],nim->dim[4]);*/
    
    pdPtr = (double *)mxGetData(mxGetField(mxnim,0,"pixdim"));
    nPixDim = (int)(mxGetM(mxGetField(mxnim,0,"pixdim"))*mxGetN(mxGetField(mxnim,0,"pixdim")));
    if(nPixDim>8) nPixDim=8;
    for(i=0; i<nPixDim; i++) nim->pixdim[i+1] = (float)pdPtr[i];
    /* DLA: fixed bug below (i was not being assigned).
     * for(nPixDim+1; i<8; i++) nim->pixdim[i] = (float)1.0; */
    for(i=nPixDim+2; i<8; i++) nim->pixdim[i] = (float)1.0;
    nim->dx = nim->pixdim[1];
    nim->dy = nim->pixdim[2];
    nim->dz = nim->pixdim[3];
    nim->dt = nim->pixdim[4];
    nim->du = nim->pixdim[5];
    nim->dv = nim->pixdim[6];
    nim->dw = nim->pixdim[7];
    
    nim->scl_slope = (float)mxGetScalar(mxGetField(mxnim,0,"scl_slope"));
    nim->scl_inter = (float)mxGetScalar(mxGetField(mxnim,0,"scl_inter"));
    nim->cal_min = (float)mxGetScalar(mxGetField(mxnim,0,"cal_min"));
    nim->cal_max = (float)mxGetScalar(mxGetField(mxnim,0,"cal_max"));
    nim->qform_code = (int)mxGetScalar(mxGetField(mxnim,0,"qform_code"));
    nim->sform_code = (int)mxGetScalar(mxGetField(mxnim,0,"sform_code"));
    nim->freq_dim = (int)mxGetScalar(mxGetField(mxnim,0,"freq_dim"));
    nim->phase_dim = (int)mxGetScalar(mxGetField(mxnim,0,"phase_dim"));
    nim->slice_dim = (int)mxGetScalar(mxGetField(mxnim,0,"slice_dim"));
    nim->slice_code = (int)mxGetScalar(mxGetField(mxnim,0,"slice_code"));
    nim->slice_start = (int)mxGetScalar(mxGetField(mxnim,0,"slice_start"));
    nim->slice_end = (int)mxGetScalar(mxGetField(mxnim,0,"slice_end"));
    nim->slice_duration = (float)mxGetScalar(mxGetField(mxnim,0,"slice_duration"));
    
    /*nim->quatern_b = (float)mxGetScalar(mxGetField(mxnim,0,"quatern_b"));
    nim->quatern_c = (float)mxGetScalar(mxGetField(mxnim,0,"quatern_c"));
    nim->quatern_d = (float)mxGetScalar(mxGetField(mxnim,0,"quatern_d"));
    
    nim->qoffset_x = (float)mxGetScalar(mxGetField(mxnim,0,"qoffset_x"));
    nim->qoffset_y = (float)mxGetScalar(mxGetField(mxnim,0,"qoffset_y"));
    nim->qoffset_z = (float)mxGetScalar(mxGetField(mxnim,0,"qoffset_z"));
    nim->qfac = (float)mxGetScalar(mxGetField(mxnim,0,"qfac"));
    nim->pixdim[0] = nim->qfac;
    */
    
    /* unpack the qto_xyz and sto_xyz matrices. */
    sxPtr = (double *)mxGetData(mxGetField(mxnim,0,"qto_xyz"));
    for(i=0; i<16; i++) nim->qto_xyz.m[i%4][i/4] = (float)sxPtr[i];
    
    sxPtr = (double *)mxGetData(mxGetField(mxnim,0,"sto_xyz"));
    for(i=0; i<16; i++) nim->sto_xyz.m[i%4][i/4] = (float)sxPtr[i];
    
    /*
     * Change origin (offset) from Matlab 1-indexing to NIFTI 0-indexing.
     */
    if(nim->qform_code>0){
        /* ensure that qto_xyz/ijk are set correctly. */
        nim->qto_ijk = nifti_mat44_inverse(nim->qto_xyz);
    	nim->qto_ijk.m[0][3] = nim->qto_ijk.m[0][3] - 1;
        nim->qto_ijk.m[1][3] = nim->qto_ijk.m[1][3] - 1;
        nim->qto_ijk.m[2][3] = nim->qto_ijk.m[2][3] - 1;
        nim->qto_xyz = nifti_mat44_inverse(nim->qto_ijk);
        nifti_mat44_to_quatern(nim->qto_xyz, 
                            &(nim->quatern_b), &(nim->quatern_c), &(nim->quatern_d),
                            &(nim->qoffset_x), &(nim->qoffset_y), &(nim->qoffset_z),
                            &(nim->pixdim[1]), &(nim->pixdim[2]), &(nim->pixdim[3]), &(nim->qfac) ) ;
    }
    if(nim->sform_code>0){
        /* ensure that sto_ijk is the inverse of sto_xyz. */
        nim->sto_ijk = nifti_mat44_inverse(nim->sto_xyz);
        nim->sto_ijk.m[0][3] = nim->sto_ijk.m[0][3] - 1;
        nim->sto_ijk.m[1][3] = nim->sto_ijk.m[1][3] - 1;
        nim->sto_ijk.m[2][3] = nim->sto_ijk.m[2][3] - 1;
        nim->sto_xyz = nifti_mat44_inverse(nim->sto_ijk);
    }
    
    nim->toffset = (float)mxGetScalar(mxGetField(mxnim,0,"toffset"));
    /* Allow units to be specified as a string */
    
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
        /* *** TO DO: support extended header fileds! */
    nim->num_ext = 0;
    
        /* I assume that we can rely on the nifti routine to byte-swap for us? */
    nifti_image_write(nim);
}
