/* dims[3] voxdims[3] origin[3] */
void InitializeApproximation(float *dtdata, long *dims, float scale, 
			     float *voxdims, float *origin);

/* coords[3] derivs[3] dt6[6] */
void GetTensorAt(float *coords, int *derivs, float *dt6);
