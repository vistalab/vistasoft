/*************************************************
*
* For more help type from a Matlab environment:
*   help grow_gray
*
* To compile it, type from a Matlab environment:
*   mex grow_gray.cpp
*
* HISTORY:
* 2008.01.XX RFD: fixed memory leaks and removed broken island removal code.
* 2008.01.27 RFD: added functional (and faster) island removal using GM flood-fill. 
* 2008.02.01 RFD: fixed pointer error (and thus segfault) in island removal code.
*
***************************************************/

#include "mex.h"
#include "matrix.h"
#include "mrGlobals.h"
#include "gray.cpp"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Parsing arguments
    const int *dim;
    int oldSize;
    
    if (nrhs < 2) mexErrMsgTxt("This function should take at least two argument");
    
    if (!mxIsNumeric(prhs[0]) || mxIsComplex(prhs[0]))
		mexErrMsgTxt("Wrong sort of data (1).");
	if (mxGetNumberOfDimensions(prhs[0]) != 3) 
        mexErrMsgTxt("Wrong number of dims (1).");
    
    dim  = mxGetDimensions(prhs[0]);
    
    if (!mxIsNumeric(prhs[1]) || mxIsComplex(prhs[1]))
		mexErrMsgTxt("Wrong sort of data (2).");
    if (mxGetM(prhs[1])*mxGetN(prhs[1]) != 1)
        mexErrMsgTxt("Wrong number of dims (2).");

    int NGrayLayers = (int) mxGetPr(prhs[1])[0];

    int layer0 = 0;
    
    int xVoi = 1, yVoi = 1, zVoi = 1;
    if (nrhs > 2) {
        xVoi = (int) mxGetPr(prhs[2])[0];
        yVoi = (int) mxGetPr(prhs[2])[2];
        zVoi = (int) mxGetPr(prhs[2])[4];
    }
    
    if (nrhs > 3) {
        if (mxGetM(prhs[3])*mxGetN(prhs[3]) != 1)
            mexErrMsgTxt("Wrong number of dims (4).");
        layer0 = ((int) mxGetPr(prhs[3])[0]);
        if (layer0 > 2) layer0 = 0;
    }

    MRVol mrvol;
    mrvol.xsize = dim[0];
    mrvol.ysize = dim[1];
    mrvol.zsize = dim[2];
    mrvol.yskip = dim[0];
    mrvol.zskip = dim[0]*dim[1];
    mrvol.cvol = (unsigned char *)mxGetPr(prhs[0]);
    mrvol.gm = NULL;
    //mexPrintf("mrvol.xsize=%d, ysize=%d, zsize=%d, yskip=%d, zskip=%d\n",mrvol.xsize,mrvol.ysize,mrvol.zsize,mrvol.yskip,mrvol.zskip);
    
    int nvoxels = mrvol.xsize*mrvol.ysize*mrvol.zsize;
    
    VOItype *voi = new VOItype;
    voi->x1 = 0;
    voi->y1 = 0;
    voi->z1 = 0;
    voi->x2 = mrvol.xsize - 1;
    voi->y2 = mrvol.ysize - 1;
    voi->z2 = mrvol.zsize - 1;
    
    CGray *GrayFuncs = new CGray();
    GrayFuncs->m_ContendWhite = 1;
	GrayFuncs->m_ContendGray = 1;
    
    GrayMatter	*gm;
 
    // Delete gray matter in cvol.
	{
		int n=mrvol.zsize*mrvol.zskip;
		unsigned char *p=mrvol.cvol;
		while (n--) {
			if (((*p)&CLASS_MASK)==GRAY_CLASS) *p=UNKNOWN_CLASS;
			p++;
		}
	}
    
    // Delete existing gray matter structure.
    if (mrvol.gm) GrayFuncs->free_gray_matter(mrvol.gm);

    // Initialise a new one... 
    gm = mrvol.gm = GrayFuncs->init_gray_matter(&mrvol);
	
    if (!gm) mexErrMsgTxt("Error! Out of memory.");
    
    // Grow the gray matter.
	{

		ASSERT(mrvol.cvol);
		ASSERT(gm->mrvol->cvol);
		ASSERT(mrvol.cvol==gm->mrvol->cvol);

        gm->layer0 = layer0;
        
		bool ret=GrayFuncs->grow_gray_layers(gm,voi->x1, voi->x2,voi->y1, voi->y2,voi->z1, voi->z2,
					NGrayLayers);

		if (!ret)
        {
            GrayFuncs->free_gray_matter(gm);
			mrvol.gm = NULL;
            mexErrMsgTxt("Error! Out of memory.");
		}
	 }
     
     /* 
      * Remove islands of gray matter, keeping only the largest gray graph. 
      * This is important, because even with a topologically correct white matter
      * volume, we can still get gray islands. Imagine a patch of the WM surface
      * with no CSF covering it, but that is surrounded by WM coated with CSF.
      * 
      * 
      */
     /*
      * Floodfill from an arbitrary node (first one). 
      * curNumNodes = count selcted nodes
      * if(curNumNodes=numGrayNodes) { finished! }
      * else if(curNumNodes>0.5*numGrayNodes){ removed unselectd nodes; finish; }
      * else { we have to count them all. Find the first unseletced node, floodfill from there; count them; find the biggest. }
      */
     GrayVoxel *curGv = gm->gm_array;
     int curNumNodes = GrayFuncs->select_gray_matter_comp(gm, curGv->x, curGv->y, curGv->z, 1);
     int maxNumNodes = curNumNodes;
     int totalNumNodes = curNumNodes;
     if(curNumNodes==gm->gm_size){
        mexPrintf("Found one GM mesh with %d nodes.\n",maxNumNodes);
     }else if(curNumNodes>0.5*gm->gm_size){
        mexPrintf("Found >1 GM mesh- keeping the first since it has %d nodes, which is > half of all nodes (%d nodes).\n",maxNumNodes,gm->gm_size);
     }else{
        int i;
        int numMeshes = 1;
        GrayVoxel *maxGv = curGv;
        for(i=gm->gm_size; i>0; i--, curGv++)
           curGv->userFlag = curGv->flag;
        bool done = false;
        mexPrintf("Found >1 GM mesh- searching for the largest mesh...\n number of nodes: ",maxNumNodes,gm->gm_size);
        do{
           mexPrintf("%d,",numMeshes,curNumNodes);
           /* Find a node that hasn't been flood-filled yet */
           curGv = gm->gm_array;
           for(i=gm->gm_size; i>0; i--, curGv++)
              if(curGv->userFlag==0) break;
           /* flood-fill it and check to see if it is connected to a bigger mesh than the biggest so far */
           curNumNodes = GrayFuncs->select_gray_matter_comp(gm, curGv->x, curGv->y, curGv->z, 1);
           totalNumNodes += curNumNodes;
           numMeshes++;
           if(curNumNodes>maxNumNodes){
              maxNumNodes = curNumNodes;
              maxGv = curGv;
           }
           curGv = gm->gm_array;
           for(i=gm->gm_size; i>0; i--, curGv++)
              if(curGv->flag!=0) curGv->userFlag = 1;
        }while(totalNumNodes < gm->gm_size);
        curNumNodes = GrayFuncs->select_gray_matter_comp(gm, maxGv->x, maxGv->y, maxGv->z, 1);
        mexPrintf("done.\nFound %d GM meshes- selecting the largest (%d nodes).\n",numMeshes,curNumNodes);
     }

	 if(gm->layer0 == 1)
        GrayFuncs->add_white_boundary(gm);
     if(gm->layer0 == 2)
        GrayFuncs->add_white_matter(gm);

     //mexPrintf("Creating outputs...");
     // Creating outputs
     plhs[0] = mxCreateDoubleMatrix(8,maxNumNodes,mxREAL);
     
     double *outNodes, *outEdges;
     outNodes = mxGetPr(plhs[0]);
     
     int total_neighbors = 0;
     int i, j;
     int curSelectedNode = 0;
     int n;
     //mexPrintf("Copying node data to output array...");
     for (i = 0 ; i < gm->gm_size; i++) {
        // Only take 'selected' GM nodes.
        if(gm->gm_array[i].flag>0){
           n = curSelectedNode*8;
           outNodes[n    ] = gm->gm_array[i].x + xVoi;
           outNodes[n + 1] = gm->gm_array[i].y + yVoi;
           outNodes[n + 2] = gm->gm_array[i].z + zVoi;
           outNodes[n + 5] = gm->gm_array[i].layer;
           // We need a look-up table to map selected nodes to the corresponding 
           // full node index. Since we don't need the layer any more, we'll take that over.
           gm->gm_array[i].layer = curSelectedNode;
           total_neighbors += gm->gm_array[i].num_gm_nbhrs;
           curSelectedNode++;
        }
     }

     //mexPrintf("Copying neighbor data to output array...");
     plhs[1] = mxCreateDoubleMatrix(1,total_neighbors,mxREAL);
     outEdges = mxGetPr(plhs[1]);
     
     int indexNeighbors = 0, neigh;
     n = 0;
     for (i = 0; i < gm->gm_size; i++) {
        // Only take 'selected' GM nodes.
        if(gm->gm_array[i].flag>0){
           neigh = gm->gm_array[i].num_gm_nbhrs;
           outNodes[n + 3] = gm->gm_array[i].num_gm_nbhrs;
           outNodes[n + 4] = indexNeighbors + 1;
           for (j = 0; j < neigh; j++){
               // Remember- the layer field contains the selected node index.
              outEdges[indexNeighbors + j] = gm->gm_array[ gm->gm_array[i].gm_nbhrs[j] ].layer + 1;
           }
           indexNeighbors += neigh;
           n+=8;
        }
     }
     
     /* 
      * CLEAN UP
      * Matlab will take care of everything it allocated. We have to explicitly
      * delete things that we allocated via new (or alloc/malloc).
      */
     //mexPrintf("Cleaning upgray matter...");
     if(gm->connex!=NULL) delete gm->connex;
     GrayFuncs->free_gray_matter(mrvol.gm);
     mrvol.gm = NULL;
     /* Don't delete mrvol.cvol becuase it was passed in (mrvol.cvol = mxGetPr(prhs[0])). */
     //mexPrintf("Deleting voi/GrayFuncs...");
     delete voi;
     delete GrayFuncs;
     
     return;
}

