//**********************************************************************
// CRemoveBridges
//
// Simple class implementing the bridge removal algorithm described
// in Kriegeskorte & Goebel (2001) An Efficient Algorithm for 
// Topologically Correct Segmentation of the Cortical Sheet in Anatomical 
// MR Volumes. Neuroimage, 14, 329-346.
//
// HISTORY:
// 2002.08.?? Niko & Rainer kindly gave us their code from BrainVoyager. 
// 2002.09.?? Ian Spiro modified the BV code to build a DLL that takes
//            data rather than filenames. He also wrote a simple mex wrapper
//            to call this DLL.
// 2002.11.13 Bob Dougherty: overhauled the code to make it cleaner (no more
//            globals!) and platform-independent. To do this, I had to remove
//            all the GUI stuff and the threading. The code now runs serially
//            and uses printf for progress reporting (although this can be
//            easily changed by modifying the updateProgress method). I also
//            wrote a mex wrapper for this class. 
// 2003.03.31 Bob Dougherty: changed 'printf' to mexPrintf'. printf works OK
//            in linux, sending messages to the console. But it doesn't work
//            in Windows.
//


#include "CRemoveBridges.h"
#include <cstdlib>
#include <cstdio>
#include <cmath>
#include <string>
using namespace std;
#include <mex.h>

//**********************************************************************
//general (P)eekable (S)tack/(Q)ueue class implemented as pointered list
//implementation 
template<class C> psqElement<C>::psqElement(C aContentOfElement, psqElement<C>* n){
  contentOfElement=aContentOfElement;
  next=n;
}

template<class C> psqElement<C>::~psqElement(){
}

template<class C> psq<C>::psq(){
  first=NULL;
  last=NULL;
  current=NULL;
  s=0;
}

template<class C> psq<C>::~psq(){
  psqElement<C>* e=first;
  while(e!=NULL){
    psqElement<C>* toBeDeleted=e;
    e=e->next;
    delete(toBeDeleted);
  }
}

template<class C> int psq<C>::size(){
  return s;
}

template<class C> bool psq<C>::stackpush(C aContentOfElement){
  //pushes at the front
  
  psqElement<C>* newFirst;
  newFirst=new psqElement<C>(aContentOfElement, first);
  
  if(newFirst==NULL) return false;
  first=newFirst;
  
  if(last==NULL) //last needs to be updated only if the list was empty before
    last=first;
  
  s++;
  return true;
}

template<class C> bool psq<C>::queuepush(C aContentOfElement){
  //pushes at the back
  psqElement<C>* newFirst;
  newLast=new psqElement<C>(aContentOfElement, NULL);
  
  if(newLast==NULL) return false;
  
  if(last==NULL) //list was empty
    first=newLast;
  else
    last->next=newLast;
  
  last=newLast;
  
  s++;
  return true;
}

template<class C> bool psq<C>::pop(C& coe){ 
  //pops the first list element (the last stackpushed or the first queuepushed element)
  if(first==NULL) return false;
  
  if(current==first)current=NULL;
  //this is the only line of the peeking implementation that slows down stack/queue operation.
  
  coe=first->contentOfElement;
  psqElement<C>* toBeDeleted=first;
  first=first->next;
  delete(toBeDeleted);
  //problem: if type C is pointer to content, this should recursively delete the the content
  //the popped pointer points to, right?
  s--;
  if(first==NULL)last=NULL;
  return true;
}

template<class C> bool psq<C>::peek(int i, C& coe){
  if((first==NULL)||(i<0))return false;
  
  psqElement<C>* cc=first;
  while(i>0){
    cc=cc->next;
    if(cc==NULL)return false;
    i--;
  }
  coe=cc->contentOfElement;
  return true;
}

template<class C> bool psq<C>::peekNext(C& coe){
  if(current==NULL)return false;
  //ambiguous: false can mean "already peeked all" (incl. the case of empty list) OR "current popped away"
  
  coe=current->contentOfElement;
  current=current->next;
  return true;
}

template<class C> void psq<C>::resetPeek(){
  current=first;
}

template<class C> psqElement<C>* psq<C>::firstPsqElementPRevealed(){
  return first;
}

/////////////////////////////////////////////////////////////////////////////
// CRemoveBridges
//
arrayFringeQueueC::arrayFringeQueueC(int bs, int mnb){
  blockSize=bs;
  maxNblocks=mnb;

  arrayOfArrays = new voxT*[maxNblocks];
	
  for(int i=0; i<maxNblocks; i++)
    arrayOfArrays[i] = NULL;
	
  cPopPos=0; 
  cPopBlock=0;
  cPushPos=0;
  cPushBlock=0;
	
  size=0;

  //pop and push indices always indicate where those operations will next be performed.
  //new storage space isn't allocated until the push that requires it is actually performed.
  //pop and push at the same point: queue empty.
  //a completely full queue is not allowed,
  //one free space is required to distinguish the full from the empty queue.
  //cPushPos=0 and cPushBlock!=cPopBlock: new block must be allocated.
}


bool arrayFringeQueueC::pop(voxT& vox){
  if( (cPopPos==cPushPos) && (cPopBlock==cPushBlock) )return false; //queue empty (underflow)
  else{
    vox=arrayOfArrays[cPopBlock][cPopPos];//pop
    size--;

    if( (cPopPos==blockSize-1)//element to be popped next is in the next block
	&&(cPopBlock!=cPushBlock) ){ //and the current pop block is not the current push block
      delete arrayOfArrays[cPopBlock]; //deallocate cPopBlock
      arrayOfArrays[cPopBlock]=NULL;
    }
						
    cPopPos++;//iterate
    if(cPopPos==blockSize){
      cPopPos=0;
      cPopBlock=(cPopBlock+1)%maxNblocks;
    }
    //hard to read concise alternative: cPopBlock=(cPopPos=(cPopPos+1)%blockSize)?cPopBlock:(cPopBlock+1)%maxNblocks;	
    return true;
  }
}

bool arrayFringeQueueC::push(voxT vox){
  if( (cPushBlock==cPopBlock && cPushPos+1==cPopPos) //push one element behind pop in the same block
      ||(cPushPos==blockSize-1 && cPopBlock==(cPushBlock+1)%maxNblocks && cPopPos==0) ) //or across blocks
    return false;//overflow (convention for differentiating full and empty states prohibits using the last space)
	
  if(arrayOfArrays[cPushBlock]==NULL){
    //block unallocated
    arrayOfArrays[cPushBlock]=new voxT[blockSize]; //allocate block
  }
	
  //everything's ready for the push
  arrayOfArrays[cPushBlock][cPushPos]=vox;//push
  size++;
	
  cPushPos++;//iterate
  if(cPushPos==blockSize){
    cPushPos=0;//next block must be used for the next push
    cPushBlock=(cPushBlock+1)%maxNblocks;
  }
  return true;
}

arrayFringeQueueC::~arrayFringeQueueC(){
  for(int i=0; i<maxNblocks; i++)
    if (arrayOfArrays[i]!=NULL) delete arrayOfArrays[i];
  delete [] arrayOfArrays;
}


//voxT implementation

voxT::voxT(int xx, int yy, int zz){x=xx;y=yy;z=zz;}
voxT::voxT(){x=0;y=0;z=0;}


//*************************
//cut description functions
cutC::cutC(){
  marked=false;
  damage=0.0;
}
cutC::~cutC(){}

choiceC::choiceC(){
  totalPosCutDamage=0.0;
  totalNegCutDamage=0.0;
}
choiceC::~choiceC(){}


//********************************************************
// METHODS FOR CRemoveBridges

CRemoveBridges::CRemoveBridges(){
  // We should have an appropriate constructor
  maxX = 255;
  minX = 0;
  maxY = 255;
  minY = 0;
  maxZ = 255;
  minZ = 0;
  elaborateCutDescriptionF = true;
  percentProgress = 0;
}
CRemoveBridges::~CRemoveBridges(){
  // We should clean up
}

void CRemoveBridges::initNegObj(){
  for (int x(0); x<256; x++)
    for (int y(0); y<256; y++)
      for (int z(0); z<256; z++){
        if(posObj[x][y][z]==0) negObj[x][y][z]=63;
        else if(posObj[x][y][z]!=0) negObj[x][y][z]=0;
      }
}

void CRemoveBridges::clearFringeNfluid(unsigned char obj[256][256][256]){
  for (int x(0); x<256; x++)
    for (int y(0); y<256; y++)
      for (int z(0); z<256; z++)
	obj[x][y][z]=obj[x][y][z]&63;
}

void CRemoveBridges::fillFrameWithAir(unsigned char obj[256][256][256]){
  for (int x(0); x<256; x++)
    for (int y(0); y<256; y++){
      obj[0][x][y]=0;
      obj[255][x][y]=0;
      obj[x][0][y]=0;
      obj[x][255][y]=0;
      obj[x][y][0]=0;
      obj[x][y][255]=0;
    }
}

void CRemoveBridges::determineBoxDimensions(unsigned char obj[256][256][256]){
  /*	minX=0; //default values
	maxX=255;
	minY=0;
	maxY=255;
	minZ=0;
	maxZ=255;
  */

  maxX=0;
  minX=255;
  maxY=0;
  minY=255;
  maxZ=0;
  minZ=255;

  nVoxInPosObj=0;

  for (int x(0); x<256; x++)
    for (int y(0); y<256; y++)
      for (int z(0); z<256; z++)
	if(obj[x][y][z]){
	  maxX= (x+1>maxX)?x+1:maxX;
	  maxY= (y+1>maxY)?y+1:maxY;
	  maxZ= (z+1>maxZ)?z+1:maxZ;
	  
	  minX= (x-1<minX)?x-1:minX;
	  minY= (y-1<minY)?y-1:minY;
	  minZ= (z-1<minZ)?z-1:minZ;
	  
	  nVoxInPosObj++;
	}
  
  nVoxInBlock=(maxX-minX+1)*(maxY-minY+1)*(maxZ-minZ+1);
  nVoxInNegObj=nVoxInBlock-nVoxInPosObj;
}

voxT CRemoveBridges::someLowestVox_normST(int zeroRingSkin, unsigned char obj[256][256][256]){
  //sets core voxels to priority zeroRingSkin and returns one zeroRingSkin-priority voxel
  voxT vox;
  
  //remember: max label=lowest.
  int max=0;

  for (int x=minX; x<=maxX; x++)
    for (int y=minY; y<=maxY; y++)
      for (int z=minZ; z<=maxZ; z++){
	obj[x][y][z]=obj[x][y][z]&63;
	if(obj[x][y][z]==63){
	  obj[x][y][z]=zeroRingSkin;
	  vox=voxT(x,y,z);
	}
	else if(obj[x][y][z]==zeroRingSkin) vox=voxT(x,y,z);
      }
  return vox;
}

void CRemoveBridges::setFrameToCoreST(int zeroRingSkin, unsigned char obj[256][256][256]){
//to be called from a separate thread
  int x,y,z;

  // x-y plane
  for (x=minX; x<=maxX; x++)
    for (y=minY; y<=maxY; y++){
      obj[x][y][minZ]=zeroRingSkin;
      obj[x][y][maxZ]=zeroRingSkin;
    }
  
  // y-z plane
  for (y=minY; y<=maxY; y++)
    for (z=minZ; z<=maxZ; z++){
      obj[minX][y][z]=zeroRingSkin;
      obj[maxX][y][z]=zeroRingSkin;
    }
  
  // x-z plane
  for (x=minX; x<=maxX; x++)
    for (z=minZ; z<=maxZ; z++){
      obj[x][minY][z]=zeroRingSkin;
      obj[x][maxY][z]=zeroRingSkin;
    }
}

void CRemoveBridges::initPasEasNSas(){
  //pas: point-adjacents
  //eas: edge-adjacents
  //sas: side-adjacents

  int i, x, y, z;
  int xx, yy, zz;
  int cpa, cea, csa;

  for(x=0; x<3; x++){
    for(y=0; y<3; y++){
      for(z=0; z<3; z++){
	i=index(x,y,z);
	if(i!=13){
	  for (cpa=0; cpa<17; cpa++)
	    pas[i][cpa]=99;
	  for (cea=0; cea<13; cea++)
	    eas[i][cea]=99;
	  for (csa=0; csa<5; csa++)
	    sas[i][csa]=99;

	  cpa=0;
	  cea=0;
	  csa=0;
										
	  for(xx=-1; xx<2; xx++){
	    for(yy=-1; yy<2; yy++){
	      for(zz=-1; zz<2; zz++){
		if((abs(xx)||abs(yy)||abs(zz)) && in3x3Block(x+xx,y+yy,z+zz) && index(x+xx,y+yy,z+zz)!=13){
		  pas[i][cpa++]=index(x+xx,y+yy,z+zz);
									
		  if(!(abs(xx)*abs(yy)*abs(zz)))
		    eas[i][cea++]=index(x+xx,y+yy,z+zz);
		  if(!(abs(xx)||abs(yy)) || !(abs(zz)||abs(yy)) || !(abs(xx)||abs(zz)))
		    sas[i][csa++]=index(x+xx,y+yy,z+zz);
		}
	      }
	    }
	  }
	}
      }
    }
  }
}



bool CRemoveBridges::surSelftouchingST(voxT centerVox, unsigned char obj[256][256][256]){
  //to be called from a separate thread
  unsigned char connex[27];
  int start(-1);
  int i;
	
  /*int maxX(255);
    int minX(0);
    int maxY(255);
    int minY(0);
    int maxZ(255);
    int minZ(0);*/

  int xx,yy,zz;

  for (int x=0; x<3; x++){
    for (int y=0; y<3; y++){
      for (int z=0; z<3; z++){
	i=x*9+y*3+z;
	
	xx=centerVox.x-1+x;
	yy=centerVox.y-1+y;
	zz=centerVox.z-1+z;
	
	if(xx>=minX && xx<=maxX && yy>=minY && yy<=maxY && zz>=minZ && zz<=maxZ)
	  if((connex[i]=obj[xx][yy][zz]&128)&&(i!=13)) start=i;
	  else
	    connex[i]=0;
      }
    }
  }
	
  connex[13]=0; //delete centerVox
	
  //LABELS in connex[]
  //air						0
  //object (former fluid)		128
  //fluid						255
  //fringe					1

  if(start==-1) //no former fluid (here object) connected to centerVox =>not selftouching
    return false;
	
  int cn=0;

  int fringe[27];
  fringe[0]=start;
  int fringeSize=1;
	
  while (fringeSize!=0){
    int v=fringe[--fringeSize]; //pop last
    connex[v]=255; //mark as fluid
    
    int neighbor;
    int cn=0;
    
    while((neighbor=eas[v][cn])!=99){
      if(connex[neighbor]==128){ //object && !fringe => 2b included
	connex[neighbor]=1; //mark as fringe
	fringe[fringeSize++]=neighbor; //push last
      }
      cn++;
    }
  }
  
  bool r=false;
  for (i=0; i<27; i++) if (connex[i]==128) r=true; //only connected via center!
  return r;
}

inline bool CRemoveBridges::inBlock(voxT vox){
  if(vox.x>=minX && vox.x<=maxX && vox.y>=minY && vox.y<=maxY && vox.z>=minZ && vox.z<=maxZ)
    return true;
  else
    return false;
}
inline bool CRemoveBridges::coreVoxAdjacentToST(int skin, voxT vox, unsigned char obj[256][256][256]){
  //is vox a core-vox bordering on skin?
  int x=vox.x; int y=vox.y; int z=vox.z;
  
  if(x<minX || x>maxX || y<minY || y>maxY || z<minZ || z>maxZ)
    return false; //outside block(<=> outside obj array)!
  
  if ((obj[x][y][z]&63)==63 && ( (obj[x-1][y][z]&63)==skin || (obj[x+1][y][z]&63)==skin ||
				 (obj[x][y-1][z]&63)==skin || (obj[x][y+1][z]&63)==skin ||
				 (obj[x][y][z-1]&63)==skin || (obj[x][y][z+1]&63)==skin ) )
    return true;
  else
    return false;
}
inline bool CRemoveBridges::outerObjVoxST(voxT vox, unsigned char obj[256][256][256]){
  //is vox an obj-vox bordering on air?
  int x=vox.x; int y=vox.y; int z=vox.z;
  
  if ((obj[x][y][z]&63)!=0 && !((obj[x-1][y][z]&63) && (obj[x+1][y][z]&63)
				&& (obj[x][y-1][z]&63) && (obj[x][y+1][z]&63)
				&& (obj[x][y][z-1]&63) && (obj[x][y][z+1]&63) ) )
    return true;
  else
    return false;
}

inline bool CRemoveBridges::volSelftouchingST(voxT centerVox, unsigned char obj[256][256][256]){
 //to be called from a separate thread

  //old definition
  //voxel x selftouching <=> set c of voxels point-adjacent to but not including x
  //contains a pair of voxels not connected in c via side-adjacency paths

  //new definition
  //voxel x selftouching <=> set c of voxels point-adjacent to but not including x
  //contains a pair of voxels not connected in c via POINT-adjacency paths
	
  //monitoring
  nVolSelftouchingChecks++;
	
  unsigned char connex[27];
  int start(-1);
  int i;
	
  int refX, refY, refZ, xx, yy, zz;

  refX=centerVox.x-1;
  refY=centerVox.y-1;
  refZ=centerVox.z-1;
	
  if(refX>=minX && refX+2<=maxX
     && refY>=minY && refY+2<=maxY
     && refZ>=minZ && refZ+2<=maxZ){ //connex doesn't intersect the outer boundary of the block
    for (int x=0; x<3; x++){
      for (int y=0; y<3; y++){
	for (int z=0; z<3; z++){
	  i=x*9+y*3+z;
	  
	  xx=refX+x;
	  yy=refY+y;
	  zz=refZ+z;
	  
	  if((connex[i]=obj[xx][yy][zz]&128)&&(i!=13)) start=i;
	}
      }
    }
  }else{
    for (int x=0; x<3; x++){
      for (int y=0; y<3; y++){
	for (int z=0; z<3; z++){
	  i=x*9+y*3+z;
	  
	  xx=refX+x;
	  yy=refY+y;
	  zz=refZ+z;
	  
	  if(xx>=minX && xx<=maxX && yy>=minY && yy<=maxY && zz>=minZ && zz<=maxZ)
	    if((connex[i]=obj[xx][yy][zz]&128)&&(i!=13)) start=i;
	    else
	      connex[i]=0;
	}
      }
    }
  }	
  
  connex[13]=0; //delete centerVox
  
  //LABELS in connex[]
  //air						0
  //object (former fluid)		128
  //fluid						255
  //fringe					1
  
  if(start==-1) //no former fluid (here object) connected to centerVox =>not selftouching
    return false;
  
  int ca=0;
  
  int fringe[27];
  fringe[0]=start;
	
  register int fringeSize; 
  fringeSize=1;
	
  register int pa;
  register int cpa;
  register int v;
		
  while (fringeSize!=0){
    v=fringe[--fringeSize]; //pop last
    connex[v]=255; //mark as fluid
    
    cpa=0;
    
    while((pa=pas[v][cpa])!=99){
      if(connex[pa]==128){ //object && !fluid && !fringe => 2b included
	connex[pa]=1; //mark as fringe
	fringe[fringeSize++]=pa; //push last
      }
      cpa++;
    }
    
    //more concise, less readable equivalent alternative
    /*		while((pa=pas[v][cpa++])!=99)
		if(connex[pa]==128) //object && !fluid && !fringe => 2b included
		connex[fringe[fringeSize++]=pa]=1; //push last, mark as fringe
    */		
  }
  
  bool r=false;
  for (i=0; i<27; i++) if (connex[i]==128) r=true; //only connected via center!
  return r;
}


int CRemoveBridges::surFloodfillST(char cSkin, voxT seedVox, unsigned char obj[256][256][256]){
  //to be called from a separate thread
  
  //returns # of surface-rings that exist with the skin marked here included in the
  //object.
  
  clearFringeNfluid(obj);

  arrayFringeQueueC prevSelftouchingFringe(256,65536); //<= 16MB*3 (256^3 voxels, 3 bytes/voxel)
  arrayFringeQueueC immaculateFringe(256,65536);

  immaculateFringe.push(seedVox);
  int fringeSize(1);

  voxT cVox;
  int nSelftouching;

  bool toBeIncluded;
  int nRings(0);

  while(true){
    if (!immaculateFringe.pop(cVox))
      if (!prevSelftouchingFringe.pop(cVox)){
	//showMessage("fringe empty.");
	break; //fringe empty!
      }
    
    
    if(surSelftouchingST(cVox, obj)){
      //showMessage("Surselftouching voxel found.");
      if (nSelftouching<fringeSize){ //other non-selftouching fringe voxels left
	prevSelftouchingFringe.push(cVox);
	nSelftouching++;
	toBeIncluded=false;
      }else{ //nSelftouching==fringeSize => fluid selftouches in all fringe voxels.
	nRings++;
	toBeIncluded=true;
      }
    }else{ //cVox not surselftouching
      toBeIncluded=true;
    }
    if (toBeIncluded){ //include cVox in fluid
      obj[cVox.x][cVox.y][cVox.z]=cSkin+128; //mark as fluid and m_cSkin
      fringeSize--;
      nSelftouching=0;
      
      // update fringe
      for(int x=-1; x<2; x++){
	for(int y=-1; y<+2; y++){
	  for(int z=-1; z<2; z++){
	    if(!(abs(x)*abs(y)*abs(z))){ //not corner <=> neighboring, not just connected
	      voxT fringeCand(cVox.x+x,cVox.y+y,cVox.z+z);
	      //showMessage(obj[fringeCand.x][fringeCand.y][fringeCand.z]);
	      if( ((obj[fringeCand.x][fringeCand.y][fringeCand.z]&(128+64))==0)&& //not yet fringe or fluid and
		  (coreVoxAdjacentToST(cSkin-1, fringeCand, obj)) ){		  //eligible fringe voxel
		//showMessage("adding a voxel to fringe...");
		obj[fringeCand.x][fringeCand.y][fringeCand.z]+=64;	//mark as fringe
		immaculateFringe.push(fringeCand);					//include in fringe set
		fringeSize++;
	      }
	    }
	  }
	}
      } //end update fringe loops
    }
  }
  return nRings;
}


float CRemoveBridges::deletionDamage(voxT vox){
  //modified to punish change: every voxel changed does damage equivalent to 1 outright misclassification

  float r_svd; //r)eturns s)ingle v)oxel d)amage
  
  //****************sectionwise linear cost function****************
  //INTENSITY of vox VALUE estimating the damage done by DELETING vox
  // 0: airDeletionDamage (negative)
  // averageGrayMatterIntensity: grayMatterDeletionDamage (negative)
  // thresholdIntensity: thresholdVoxDeletionDamage (0)
  // averageWhiteMatterIntensity: whiteMatterDeletionDamage (positive)
  // 255: whitestMatterDeletionDamage (positive)
    
  const float airDeletionDamage = -10.0;
  const float grayMatterDeletionDamage = -1.0;
  const float thresholdVoxDeletionDamage = 0.0;
  const float whiteMatterDeletionDamage = 1.0;
  const float whitestMatterDeletionDamage = 1.5;
  
  float intensity=float(unsegVMRobj[vox.x][vox.y][vox.z]);
  
  if(intensity<g_averageGrayIntensity) //air to gray matter
    r_svd=airDeletionDamage+intensity/g_averageGrayIntensity*(grayMatterDeletionDamage-airDeletionDamage);
  
  else if(g_averageGrayIntensity<=intensity && intensity<g_thresholdIntensity) //gray matter to threshold
    r_svd=grayMatterDeletionDamage+(intensity-g_averageGrayIntensity)/(g_thresholdIntensity-g_averageGrayIntensity)*(thresholdVoxDeletionDamage-grayMatterDeletionDamage);
  
  else if(g_thresholdIntensity<=intensity && intensity<g_averageWhiteIntensity) //threshold to white matter
    r_svd=thresholdVoxDeletionDamage+(intensity-g_thresholdIntensity)/(g_averageWhiteIntensity-g_thresholdIntensity)*(whiteMatterDeletionDamage-thresholdVoxDeletionDamage);
  
  else if(g_averageWhiteIntensity<=intensity) //white matter to totally white
    r_svd=whiteMatterDeletionDamage+(intensity-g_averageWhiteIntensity)/(255-g_averageWhiteIntensity)*(whitestMatterDeletionDamage-whiteMatterDeletionDamage);
  
  r_svd+=1.0; //punish change
  
  //logFileS=logFileS+"\ndeletion of voxel of intensity "+toCString(intensity)+" causes "+toCString(r_svd)+" damage.\n";
  return r_svd;
}

float CRemoveBridges::additionDamage(voxT vox){
  //modified to punish change: every voxel changed does damage equivalent to 1 outright misclassification
	
  float r_svd; //r)eturns s)ingle v)oxel d)amage

  //****************sectionwise linear cost function****************
  //INTENSITY of vox				VALUE estimating the damage done by ADDING vox
  //0								airAdditionDamage (positive)
  //averageGrayMatterIntensity	grayMatterAdditionDamage (positive)
  //thresholdIntensity		thresholdVoxAdditionDamage (0)
  //averageWhiteMatterIntensity	whiteMatterAdditionDamage (negative)
  //255				whitestMatterAdditionDamage (negative)

  const float airAdditionDamage = 10.0;
  const float grayMatterAdditionDamage = 1.0;
  const float thresholdVoxAdditionDamage = 0.0;
  const float whiteMatterAdditionDamage = -1.0;
  const float whitestMatterAdditionDamage = -1.5;

  float intensity=float(unsegVMRobj[vox.x][vox.y][vox.z]);
  
  if(intensity<g_averageGrayIntensity) //air to gray matter
    r_svd=airAdditionDamage+intensity/g_averageGrayIntensity*(grayMatterAdditionDamage-airAdditionDamage);
  
  else if(g_averageGrayIntensity<=intensity && intensity<g_thresholdIntensity) //gray matter to threshold
    r_svd=grayMatterAdditionDamage+(intensity-g_averageGrayIntensity)/(g_thresholdIntensity-g_averageGrayIntensity)*(thresholdVoxAdditionDamage-grayMatterAdditionDamage);
  
  else if(g_thresholdIntensity<=intensity && intensity<g_averageWhiteIntensity) //threshold to white matter
    r_svd=thresholdVoxAdditionDamage+(intensity-g_thresholdIntensity)/(g_averageWhiteIntensity-g_thresholdIntensity)*(whiteMatterAdditionDamage-thresholdVoxAdditionDamage);
  
  else if(g_averageWhiteIntensity<=intensity) //white matter to totally white
    r_svd=whiteMatterAdditionDamage+(intensity-g_averageWhiteIntensity)/(255-g_averageWhiteIntensity)*(whitestMatterAdditionDamage-whiteMatterAdditionDamage);
  
  r_svd+=1.0; //punish change
  
  //logFileS=logFileS+"\naddition of voxel of intensity "+toCString(intensity)+" causes "+toCString(r_svd)+" damage.\n";
  return r_svd;
}


bool CRemoveBridges::uVolFloodfillST(voxT seedVox, psq<cutC*>& listOfCutPs, unsigned char obj[256][256][256]){

  //returns true if successful.
  //no volume-rings (=bridges!) exist in the fluid marked in obj[][][].
	
  int i;
  
  bool describingCuts(false); //true while the voxels belonging to each cut are being listed
  bool cCutDescribed(false); //true when finished describing the current cut (another selftouching voxel needs to be included.)
  cutC* cCutP; 	//current cut while describing cuts
  cCutP=NULL;
  
  unsigned char lowestFringeLevel=obj[seedVox.x][seedVox.y][seedVox.z];
	
  if(lowestFringeLevel<1||lowestFringeLevel>63) return false;
  //error: seedVox is air (there seems to be no object) or fringe&fluid haven't been cleared.

  arrayFringeQueueC* fringeAtDepth[63];	//allocate memory for fringe set storage
  for(i=0; i<lowestFringeLevel; i++)
    fringeAtDepth[i]=new arrayFringeQueueC(4096,4096);

  fringeAtDepth[lowestFringeLevel-1]->push(seedVox);
  int fringeSize(1);

  voxT cVox;
  int nSelftouching;

  int nBridges(0);

  //for quick access to adjacent voxels
  int xx[6]={-1,1,0,0,0,0};
  int yy[6]={0,0,-1,1,0,0};
  int zz[6]={0,0,0,0,-1,1};
	
  //Invalidate();

  while(true){
    nSelftouching=0;
    
    //think of a fluid flooding a landscape from one point. this is the depth of the fluid surface in the pond
    //where the depth is still changing.
    int lowestNonselftouchingFringeLevel=lowestFringeLevel;
    
    while(true){ //choose the next fringe voxel to be included
      char movingSurDepth=lowestNonselftouchingFringeLevel;
      while(movingSurDepth>0 && !fringeAtDepth[movingSurDepth-1]->pop(cVox)){
	movingSurDepth--;
      }
      
      if(movingSurDepth==0){ //fringe empty. all cuts have been described.
	for(i=0; i<lowestFringeLevel; i++)//deallocate memory for fringe set storage
	  delete fringeAtDepth[i];
	
	if(describingCuts)
	  listOfCutPs.stackpush(cCutP);
	
	//about to describe the cut list in english...
	//describeCutListInEnglish(listOfCutPs);
	
	return true;
      }
      
      if(cCutDescribed){ //in cut description mode and finished describing the current cut 
	cCutDescribed=false;
	break; //include ONE selftouching voxel, start describing the next cut
      }
      
      if(volSelftouchingST(cVox,obj)){
	nSelftouching++;
	fringeAtDepth[movingSurDepth-1]->push(cVox);//put it back
	
	if(nSelftouching==fringeAtDepth[movingSurDepth-1]->size){ //nSelftouching==fringeSize => fluid selftouches in all fringe voxels at movingSurDepth.
	  if(movingSurDepth==1){ //no more nonselftouching voxels in the fringe set
	    
	    //start describing the next cut: cVox, its first voxel, is included below
	    cCutDescribed=true; //one selftouching voxel needs to be included
	    
	    if(describingCuts)
	      listOfCutPs.stackpush(cCutP);
	    else 
	      describingCuts=true;
	    
	    //inititalize cCutP to represent the next cut
	    cCutP=new cutC();
	    
	    cCutP->damage=0;
	  }else{
	    lowestNonselftouchingFringeLevel--;
	    nSelftouching=0;
	  }
	}
	
      }
      else break; //not volSelftouching => take this fringe voxel
    }
    
    //fringe not empty yet.
    //chosen cVox not volselftouching OR in cut description mode (describingCuts==true)
    
    //include cVox in fluid
    obj[cVox.x][cVox.y][cVox.z]=(obj[cVox.x][cVox.y][cVox.z]&63)+128; //mark as fluid
    
    //progress indication
    if(obj==posObj){
      nVoxIncludedInPosObj++;
      if(nVoxIncludedInPosObj%100==0)
	updateProgress(int(100*(surfaceFillingTimeProportion
				+ volFloodFillTimeProportion * 0.5
				* ((float(nVoxIncludedInPosObj)/float(nVoxInPosObj))
				   + (float(nVoxIncludedInNegObj)/float(nVoxInNegObj))))));
    }else{
      nVoxIncludedInNegObj++;
      if(nVoxIncludedInNegObj%100==0)
	updateProgress(int(100*(surfaceFillingTimeProportion
				+ volFloodFillTimeProportion * 0.5
				* ((float(nVoxIncludedInPosObj)/float(nVoxInPosObj))
				   + (float(nVoxIncludedInNegObj)/float(nVoxInNegObj))))));
    }
    
    //if in cut description mode...
    if(describingCuts){
      if(outerObjVoxST(cVox, obj))//cVox in the contour
	cCutP->cutContour.stackpush(cVox);
      else
	cCutP->cutFilling.stackpush(cVox);
      
      //computation of the damage the cut does to the segmentation
      if(obj==posObj)
	cCutP->damage+=deletionDamage(cVox);
      else
	cCutP->damage+=additionDamage(cVox);
    }
    
    //update fringe
    for(int i=0; i<6; i++){
      voxT fringeCand(cVox.x+xx[i],cVox.y+yy[i],cVox.z+zz[i]);
      if( (fringeCand.x>=minX && fringeCand.x<=maxX && fringeCand.y>=minY && fringeCand.y<=maxY && fringeCand.z>=minZ && fringeCand.z<=maxZ) //inside block(<=> inside obj array)!
	  && ((obj[fringeCand.x][fringeCand.y][fringeCand.z]&(128+64))==0) //not yet fringe or fluid and
	  && (obj[fringeCand.x][fringeCand.y][fringeCand.z]>0) ){ //not air => eligible fringe voxel
	//mark as fringe
	obj[fringeCand.x][fringeCand.y][fringeCand.z]+=64;
	
	//include in fringe set
	fringeAtDepth[(obj[fringeCand.x][fringeCand.y][fringeCand.z]&63)-1]->
	  push(fringeCand);
	
	//let it trickle down if possible
	if((obj[fringeCand.x][fringeCand.y][fringeCand.z]&63)>lowestFringeLevel)
	  lowestFringeLevel=obj[fringeCand.x][fringeCand.y][fringeCand.z]&63;
      }
    }	// end update fringe loop
  }
}

bool CRemoveBridges::existsCoreAdjacentToST(char skin, voxT& vox, unsigned char obj[256][256][256]){
  for (; vox.x<maxX; vox.x++){
    for (; vox.y<maxY; vox.y++){
      for (; vox.z<maxZ; vox.z++){
	if (coreVoxAdjacentToST(skin, vox, obj)) return true;
      }
      vox.z=minZ;
    }
    vox.y=minY;
  }
  vox.x=minX;
  return false;
}


//normal and inverse cutting
bool CRemoveBridges::cutAllST(psq<cutC*>& listOfCutPs, unsigned char obj[256][256][256]){
  initPasEasNSas();
  char cSkin=1;
  voxT seedVox;
  int nSurRings=1;
  int startProgress = this->percentProgress;

  //keep skinning while rings still exist.
  showMessage("   Eroding...");
  while(nSurRings>0 && cSkin<63){
    nSurRings=0;
    seedVox.x=minX; seedVox.y=minY; seedVox.z=minZ;
    while(existsCoreAdjacentToST(cSkin-1, seedVox, obj)){
      nSurRings+=surFloodfillST(cSkin, seedVox, obj); 
    }
    cSkin++;
    updateProgress(startProgress + int(0.5+100.0*surfaceFillingTimeProportion*cSkin/63.0));
  }
  
  //volume filling...;
  clearFringeNfluid(obj);
  showMessage("   Flood-filling volume...");
  if(!uVolFloodfillST(someLowestVox_normST(cSkin-1, obj), listOfCutPs, obj)) return false;
  
  return true;
}	



//*******************************
//describe cuts in english

string CRemoveBridges::englishCutDescriptionElaboration(cutC* cutP){
  //returns an abstract description of the cut (centroid, #voxels, NL) as a string
	
  string r_description;

  int nVoxels=0;

  voxT cVox;
  string voxelTypeS, actionTypeS;
  float damage;
  char buff[256];

  //compute centroid
  cutP->cutContour.resetPeek();
  while(cutP->cutContour.peekNext(cVox)){
    if(posObj[cVox.x][cVox.y][cVox.z]==0){ //if air voxel
      voxelTypeS = "air";
      actionTypeS = "added";
      damage=additionDamage(cVox);
    }else{ //object voxel
      voxelTypeS = "object";
      actionTypeS = "deleted";
      damage=deletionDamage(cVox);
    }

    sprintf(buff, "\t\t\t%s voxel (%d,%d,%d) of intensity %d doing %f damage if %s.\n", 
	    voxelTypeS.c_str(), cVox.z, cVox.x, cVox.y, unsegVMRobj[cVox.x][cVox.y][cVox.z], 
	    damage, actionTypeS.c_str());
    r_description = r_description+buff;
  }
  
  cutP->cutFilling.resetPeek();
  while(cutP->cutFilling.peekNext(cVox)){
    if(posObj[cVox.x][cVox.y][cVox.z]==0){ //if air voxel
      voxelTypeS="air";
      actionTypeS="added";
      damage=additionDamage(cVox);
    }else{ //object voxel
      voxelTypeS="object";
      actionTypeS="deleted";
      damage=deletionDamage(cVox);
    }
    
    sprintf(buff, "\t\t\t%s voxel (%d,%d,%d) of intensity %d doing %f damage if %s.\n", 
	    voxelTypeS.c_str(), cVox.z, cVox.x, cVox.y, unsegVMRobj[cVox.x][cVox.y][cVox.z], 
	    damage, actionTypeS.c_str());
    r_description = r_description+buff;
  }
  
  return r_description;
}

string CRemoveBridges::englishCutDescription(cutC* cutP){
  //returns an abstract description of the cut (centroid, #voxels, NL) as a string
	
  string r_description;

  int nVoxels=0;

  double centroidX(0), centroidY(0), centroidZ(0);
	
  voxT cVox;

  //compute centroid
  cutP->cutContour.resetPeek();
  while(cutP->cutContour.peekNext(cVox)){
    nVoxels++;
		
    centroidX+=cVox.x;
    centroidY+=cVox.y;
    centroidZ+=cVox.z;
  }

  cutP->cutFilling.resetPeek();
  while(cutP->cutFilling.peekNext(cVox)){
    nVoxels++;
		
    centroidX+=cVox.x;
    centroidY+=cVox.y;
    centroidZ+=cVox.z;
  }

  centroidX/=double(nVoxels);
  centroidY/=double(nVoxels);
  centroidZ/=double(nVoxels);

  char buff[256];
  sprintf(buff, "\t\t%d voxels doing %f damage at centroid: (%d,%d,%d).\n", 
	  nVoxels, cutP->damage, round(centroidZ), round(centroidX), round(centroidY));
  r_description = r_description+buff;

  if(elaborateCutDescriptionF) r_description = r_description+englishCutDescriptionElaboration(cutP);


  return r_description;
}

string CRemoveBridges::englishCutListDescription(psq<cutC*>& listOfCutPs){
  string r_description;

  cutC* cCutP; //current cut pointer
			
  int cCutI=1;
  char buff[256];

  listOfCutPs.resetPeek();
  while(listOfCutPs.peekNext(cCutP)){
    sprintf(buff, "cut: %d\t.\n", cCutI++);
    r_description = r_description+buff+englishCutDescription(cCutP);
  }
  return r_description;
}

string CRemoveBridges::englishChoiceListDescription(psq<choiceC*>& listOfChoicePs){
  string r_description;
	
  choiceC* cChoiceP;
  int cChoiceI = 1;
  char buff[256];

  r_description = r_description+"_________________________________\n";
	
  listOfChoicePs.resetPeek();
  while(listOfChoicePs.peekNext(cChoiceP)){
    sprintf(buff, "\n\nCHOICE: %d", cChoiceI++);
    r_description = r_description+buff
      +"\n\npositive cuts\n"+englishCutListDescription(cChoiceP->listOfPosCutPs)
      +"\nnegative cuts\n"+englishCutListDescription(cChoiceP->listOfNegCutPs);
  }
  return r_description;
}

bool CRemoveBridges::writeLogFile(char *filespec){
  FILE* myFileStream;
	
  if( (myFileStream = fopen(filespec,"wt")) != NULL ){
    fwrite(logFileS.c_str(), sizeof(char), logFileS.length(), myFileStream);
    fclose(myFileStream);
    return true;
  }else{
    showMessage("File couldn't be opened.");
    return false;
  }
}


//*********************************
//load and save the presegmented and unsegmented VMRs
bool CRemoveBridges::loadPresegVMR(char *filespec){
  FILE* myFileStream;
  if( (myFileStream = fopen(filespec,"rb")) != NULL ){
    //read header
    fread(vmrHeaderBuffer, sizeof(char), 6, myFileStream);
    //read data
    for (int z=0; z<256; z++)
      for (int y=0; y<256; y++)
	for (int x=0; x<256; x++){
	  fread(&posObj[x][y][z],sizeof(char),1,myFileStream);
	  if(posObj[x][y][z]!=0) posObj[x][y][z]=63;
	}
    fclose(myFileStream);
    return true;
  }else{
    return false;
  }
}

bool CRemoveBridges::loadUnsegVMR(char *filespec){
  FILE* myFileStream;	
  if( (myFileStream = fopen(filespec,"rb")) != NULL ){
    //read header
    fread(vmrHeaderBuffer, sizeof(char), 6, myFileStream);
    //read data
    for (int z=0; z<256; z++)
      for (int y=0; y<256; y++)
	for (int x=0; x<256; x++){
	  fread(&unsegVMRobj[x][y][z],sizeof(char),1,myFileStream);
	}
    fclose(myFileStream);
    return true;
  }else{
    return false;
  }
}

bool CRemoveBridges::saveBridgelessVMR(char *filespec){
  FILE* myFileStream;
  unsigned int vmrHeader[3];
  vmrHeader[0]=56;	
  vmrHeader[1]=156;
  vmrHeader[2]=256;
  if( (myFileStream = fopen(filespec,"wb")) != NULL ){
    //write header
    //fwrite(vmrHeaderBuffer, sizeof(char), 6, myFileStream);
    fwrite(vmrHeader, sizeof(unsigned int), 3, myFileStream);
    unsigned char voxelIntensity;
    //write data
    for (int z=0; z<256; z++)
      for (int y=0; y<256; y++)
	for (int x=0; x<256; x++){
	  voxelIntensity=posObj[x][y][z];
	  if(voxelIntensity!=cidAdded && voxelIntensity!=cidRemoved && voxelIntensity!=cidUnchangedAir)
	    if(voxelIntensity&128) //if in fluid
	      voxelIntensity=cidUnchangedObj;
	    else voxelIntensity=cidUnchangedAir;
	  fwrite(&voxelIntensity,sizeof(char),1,myFileStream);
	}
      fclose(myFileStream);
      return true;
  }else{
    return false;
  }
}

bool CRemoveBridges::saveVisualizationVMR(char *filespec){
  FILE* myFileStream;
  if( (myFileStream = fopen(filespec,"wb")) != NULL ){
    //write header
    fwrite(vmrHeaderBuffer, sizeof(char), 6, myFileStream);		
    unsigned char voxelIntensity;
    //write data
    for (int z=0; z<256; z++)
      for (int y=0; y<256; y++)
	for (int x=0; x<256; x++){
	  voxelIntensity=unsegVMRobj[x][y][z];
	  fwrite(&voxelIntensity,sizeof(char),1,myFileStream);
	}				
    fclose(myFileStream);	
    return true;
  }else{
    return false;
  }
}


//*********************************
//decide which cuts are to be made
void CRemoveBridges::searchPartners_zerocrossing(cutC* sourceCutP, bool targetCutNegF, psq<cutC*>& sourceListOfCutPs, psq<cutC*>& targetListOfCutPs, choiceC* cChoiceP){
  //searches all partners RECURSIVELY, and adds them to the current choice (cChoiceP)
	
  psqElement<cutC*>* cTargetCutPpsqElP;
  cutC* cTargetCutP;

  cTargetCutPpsqElP=targetListOfCutPs.firstPsqElementPRevealed();//iterate through all target cuts
  while(cTargetCutPpsqElP!=NULL){
    cTargetCutP=cTargetCutPpsqElP->contentOfElement;

    //determine if source and target cut touch
    if(!cTargetCutP->marked){
      psqElement<voxT>* cSourceVoxPsqElP;
      psqElement<voxT>* cTargetVoxPsqElP;
      voxT cSourceVox, cTargetVox;
      bool touchingEstablished=false;
		
      //check every pair of outer voxels between source and target for side-adjacency

      cSourceVoxPsqElP=sourceCutP->cutContour.firstPsqElementPRevealed();  
      //iterate through all outer source cut voxels
      while(cSourceVoxPsqElP!=NULL){
	cSourceVox=cSourceVoxPsqElP->contentOfElement;
	cTargetVoxPsqElP=cTargetCutP->cutContour.firstPsqElementPRevealed(); 
	//iterate through all outer target cut voxels
	while(cTargetVoxPsqElP!=NULL){
	  cTargetVox=cTargetVoxPsqElP->contentOfElement;
	  //  if(abs(cSourceVox.x-cTargetVox.x)
	  //	 +abs(cSourceVox.y-cTargetVox.y)
	  //	 +abs(cSourceVox.z-cTargetVox.z)==1)//two voxels between source and target cuts are side-adjacent!!

	  if(abs(cSourceVox.x-cTargetVox.x)<2 &&
	     abs(cSourceVox.y-cTargetVox.y)<2 &&
	     abs(cSourceVox.z-cTargetVox.z)<2){ //two voxels between source and target cuts are point-adjacent!!
	    cTargetCutP->marked=true;
	    if(targetCutNegF){
	      cChoiceP->listOfNegCutPs.stackpush(cTargetCutP);	
	      //computation of total damage for NEGAtive cut set
	      cChoiceP->totalNegCutDamage+=cTargetCutP->damage;
	    }else{
	      cChoiceP->listOfPosCutPs.stackpush(cTargetCutP);
	      //computation of total damage for POSItive cut set
	      cChoiceP->totalPosCutDamage+=cTargetCutP->damage;
	    }

	    searchPartners_zerocrossing(cTargetCutP, !targetCutNegF, targetListOfCutPs, sourceListOfCutPs, cChoiceP); 
	    //RECURSIVE search!!

	    touchingEstablished=true; //touching of source and target has been established
	    break;//exit inner while loop (outer target voxel iteration)
	  }

	  cTargetVoxPsqElP=cTargetVoxPsqElP->next;
	}
	if(touchingEstablished)break; //exit outer while loop (outer source voxel iteration)
			
	cSourceVoxPsqElP=cSourceVoxPsqElP->next;
      }
      //source and target cut don't touch
    }
    cTargetCutPpsqElP=cTargetCutPpsqElP->next;
  }
  //all target cuts have been examined and all touchings archived
}

void CRemoveBridges::searchPartners(cutC* sourceCutP, bool sourceCutPosF, psq<cutC*>& sourceListOfCutPs, psq<cutC*>& targetListOfCutPs, choiceC* cChoiceP){
  //searches all partners RECURSIVELY, and adds them to the current choice (cChoiceP)
	
  psqElement<cutC*>* cTargetCutPpsqElP;
  cutC* cTargetCutP;

  //search the other cuts OF THE SAME TYPE recursively ("zerocrossing")
  cTargetCutPpsqElP=sourceListOfCutPs.firstPsqElementPRevealed();//iterate through all target cuts
  while(cTargetCutPpsqElP!=NULL){
    cTargetCutP=cTargetCutPpsqElP->contentOfElement;

    //determine if source and target cut touch
    if(!cTargetCutP->marked){
      psqElement<voxT>* cSourceVoxPsqElP;
      psqElement<voxT>* cTargetVoxPsqElP;
      voxT cSourceVox, cTargetVox;
      bool touchingEstablished=false;
		
      //check every pair of outer voxels between source and target for side-adjacency

      cSourceVoxPsqElP=sourceCutP->cutContour.firstPsqElementPRevealed();  
      //iterate through all outer source cut voxels
      while(cSourceVoxPsqElP!=NULL){
	cSourceVox=cSourceVoxPsqElP->contentOfElement;

	cTargetVoxPsqElP=cTargetCutP->cutContour.firstPsqElementPRevealed(); 
	//iterate through all outer target cut voxels
	while(cTargetVoxPsqElP!=NULL){
	  cTargetVox=cTargetVoxPsqElP->contentOfElement;
	
	  if(abs(cSourceVox.x-cTargetVox.x)<2 &&
	     abs(cSourceVox.y-cTargetVox.y)<2 &&
	     abs(cSourceVox.z-cTargetVox.z)<2){ //two voxels between source and target cuts are point-adjacent!!
	    cTargetCutP->marked=true;
	    if(sourceCutPosF){
	      cChoiceP->listOfPosCutPs.stackpush(cTargetCutP);

	      //computation of total damage for POSItive cut set
	      cChoiceP->totalPosCutDamage+=cTargetCutP->damage;
	    }else{
	      cChoiceP->listOfNegCutPs.stackpush(cTargetCutP);
				
	      //computation of total damage for NEGAtive cut set
	      cChoiceP->totalNegCutDamage+=cTargetCutP->damage;
	    }

	    searchPartners(cTargetCutP, sourceCutPosF, sourceListOfCutPs, targetListOfCutPs, cChoiceP); //RECURSIVE search!!

	    touchingEstablished=true; //touching of source and target has been established
	    break;//exit inner while loop (outer target voxel iteration)
	  }

	  cTargetVoxPsqElP=cTargetVoxPsqElP->next;
	}
	if(touchingEstablished)break; //exit outer while loop (outer source voxel iteration)
			
	cSourceVoxPsqElP=cSourceVoxPsqElP->next;
      }
      //source and target cut don't touch
    }
    cTargetCutPpsqElP=cTargetCutPpsqElP->next;
  }
  //all target cuts OF THE SAME TYPE have been examined and all touchings archived

  //search the other cuts OF THE OTHER TYPE recursively ("zerocrossing")
  cTargetCutPpsqElP=targetListOfCutPs.firstPsqElementPRevealed();//iterate through all target cuts
  while(cTargetCutPpsqElP!=NULL){
    cTargetCutP=cTargetCutPpsqElP->contentOfElement;

    //determine if source and target cut touch
    if(!cTargetCutP->marked){
      psqElement<voxT>* cSourceVoxPsqElP;
      psqElement<voxT>* cTargetVoxPsqElP;
      voxT cSourceVox, cTargetVox;
      bool touchingEstablished=false;
		
      //check every pair of outer voxels between source and target for side-adjacency

      cSourceVoxPsqElP=sourceCutP->cutContour.firstPsqElementPRevealed();  //iterate through all outer source cut voxels
      while(cSourceVoxPsqElP!=NULL){
	cSourceVox=cSourceVoxPsqElP->contentOfElement;

	cTargetVoxPsqElP=cTargetCutP->cutContour.firstPsqElementPRevealed(); //iterate through all outer target cut voxels
	while(cTargetVoxPsqElP!=NULL){
	  cTargetVox=cTargetVoxPsqElP->contentOfElement;
	
	  if(abs(cSourceVox.x-cTargetVox.x)<2 &&
	     abs(cSourceVox.y-cTargetVox.y)<2 &&
	     abs(cSourceVox.z-cTargetVox.z)<2){ //two voxels between source and target cuts are point-adjacent!!
	    cTargetCutP->marked=true;
	    if(sourceCutPosF){
	      cChoiceP->listOfNegCutPs.stackpush(cTargetCutP);
				
	      //computation of total damage for NEGAtive cut set
	      cChoiceP->totalNegCutDamage+=cTargetCutP->damage;
	    }else{
	      cChoiceP->listOfPosCutPs.stackpush(cTargetCutP);

	      //computation of total damage for POSItive cut set
	      cChoiceP->totalPosCutDamage+=cTargetCutP->damage;
	    }

	    searchPartners(cTargetCutP, !sourceCutPosF, targetListOfCutPs, sourceListOfCutPs, cChoiceP); 
	    //RECURSIVE search!!

	    touchingEstablished=true; //touching of source and target has been established
	    break;//exit inner while loop (outer target voxel iteration)
	  }

	  cTargetVoxPsqElP=cTargetVoxPsqElP->next;
	}
	if(touchingEstablished)break; //exit outer while loop (outer source voxel iteration)
			
	cSourceVoxPsqElP=cSourceVoxPsqElP->next;
      }
      //source and target cut don't touch
    }
    cTargetCutPpsqElP=cTargetCutPpsqElP->next;
  }
  //all target cuts OF THE OTHER TYPE have been examined and all touchings archived
}

bool CRemoveBridges::establishCorrespondence(psq<cutC*>& listOfPosCutPs, psq<cutC*>& listOfNegCutPs, psq<choiceC*>& listOfChoicePs){	
  psqElement<cutC*>* cPosCutPpsqElP;
  cutC* cPosCutP;

  int cChoiceI=0;

  cPosCutPpsqElP=listOfPosCutPs.firstPsqElementPRevealed(); //iterate through all positive cuts
  while(cPosCutPpsqElP!=NULL){
    cPosCutP=cPosCutPpsqElP->contentOfElement;

    if(!cPosCutP->marked){ // if not assigned to a choice yet..
      //create new choice
      cChoiceI++;
			
      choiceC* cChoiceP=new choiceC();
      cChoiceP->choiceI=cChoiceI;
			
      listOfChoicePs.stackpush(cChoiceP); //create a "file" for the choice

      cChoiceP->listOfPosCutPs.stackpush(cPosCutP); //add current pos. cut to the current choice

      //computation of total damage (separately for positive and negative cut sets)
      cChoiceP->totalPosCutDamage+=cPosCutP->damage;
			
      //mark the current pos. cut as "assigned"
      cPosCutP->marked=true;
      searchPartners(cPosCutP, true, listOfPosCutPs, listOfNegCutPs, cChoiceP); //RECURSIVE search for partners
    }
    cPosCutPpsqElP=cPosCutPpsqElP->next;
  }
  //all corresponding cuts have been organized in choice "files", positives and negatives separately.
  //the choice "files" are returned in listOfChoicePs.
	
  //log this information
  logFileS=logFileS+englishChoiceListDescription(listOfChoicePs);
	
  return true;
}

float CRemoveBridges::cutSetCost(choiceC* cChoiceP, bool posCutSetCostF){
  if(g_choiceHeuristic==-1){ 
    //"heuristic" -1: always choose negative cuts (only addition)
    if(posCutSetCostF)
      return 99;
    else
      return 0;
  }
  else if(g_choiceHeuristic==0){ 
    //"heuristic" 0: always choose POSItive cuts (only DELEtion)
    if(posCutSetCostF)
      return 0;
    else
      return 99;
  }	
  else if(g_choiceHeuristic==1){ 
    //heuristic 1: choose the cut set inverting less voxels
    float r_cutCost=0;

    psq<cutC*>* listOfCutPsP;

    if(posCutSetCostF)
      listOfCutPsP=&(cChoiceP->listOfPosCutPs);
    else
      listOfCutPsP=&(cChoiceP->listOfNegCutPs);

    //iterate through all cuts
    listOfCutPsP->resetPeek();
    cutC* cCutP;
		
    while(listOfCutPsP->peekNext(cCutP))
      r_cutCost+=float(cCutP->cutContour.size()+cCutP->cutFilling.size()); //add up # voxels
		
    return r_cutCost; //sum of # voxels across all cuts
  }

  else if(g_choiceHeuristic==2){
    //heuristic 2: choose the cut set doing less total damage (sum of single voxel damage estimates across all inverted voxels)
    if(posCutSetCostF)
      return cChoiceP->totalPosCutDamage;
    else
      return cChoiceP->totalNegCutDamage;
  }

  //error: choice heuristic doesn't exist.
  showMessage("Indicated choice heuristic doesn't exist.");
  return -999.0; 
}

void CRemoveBridges::setTheseCutsTo(psq<cutC*>& listOfCutPs, unsigned char newCid, bool logF, unsigned char obj[256][256][256]){
  //makes NEGATIVE cuts by setting cidAir-voxels to cidAdded
  cutC* cCutP;
  
  listOfCutPs.resetPeek();
  while(listOfCutPs.peekNext(cCutP)){
    //log this information
    if(logF)logFileS=logFileS+englishCutDescription(cCutP);
    
    //make one cut
    voxT cVox;
    
    cCutP->cutContour.resetPeek();
    while(cCutP->cutContour.peekNext(cVox))
      obj[cVox.x][cVox.y][cVox.z]=newCid;
    
    cCutP->cutFilling.resetPeek();
    while(cCutP->cutFilling.peekNext(cVox))
      obj[cVox.x][cVox.y][cVox.z]=newCid;
  }
}

	
void CRemoveBridges::makeChanges(psq<choiceC*>& listOfChoicePs, unsigned char obj[256][256][256]){
  char buff[256];
  sprintf(buff,"\n_______________________________\nCHANGES CHOSEN (by heuristic %d)\n",g_choiceHeuristic);
  logFileS=logFileS+buff;
	
  choiceC* cChoiceP;
  int choiceI=1;
	
  listOfChoicePs.resetPeek();
  while(listOfChoicePs.peekNext(cChoiceP)){
    sprintf(buff, "\nchoice: %d\n", choiceI++);
    logFileS=logFileS+buff;
		
    if(cutSetCost(cChoiceP, true) > cutSetCost(cChoiceP, false)){ // if POSItive cut set cost greater
      logFileS = logFileS+"\n\tadded:\n";
      setTheseCutsTo(cChoiceP->listOfNegCutPs, cidAdded, true, obj); 

      if(g_visualizationVMR_F){
	setTheseCutsTo(cChoiceP->listOfNegCutPs, cidAdded, false, unsegVMRobj); 
	setTheseCutsTo(cChoiceP->listOfPosCutPs, cidAlternative, false, unsegVMRobj); //mark alternative cuts not chosen!
      }
    }else{ // if NEGAtive cut set cost greater
      logFileS=logFileS+"\n\tremoved:\n";
      setTheseCutsTo(cChoiceP->listOfPosCutPs, cidRemoved, true, obj);

      if(g_visualizationVMR_F){
	setTheseCutsTo(cChoiceP->listOfPosCutPs, cidRemoved, false, unsegVMRobj); 
	setTheseCutsTo(cChoiceP->listOfNegCutPs, cidAlternative, false, unsegVMRobj); 
	//mark alternative cuts not chosen!
      }
    }
  }		
}


unsigned char CRemoveBridges::remove(unsigned char *preSegData,
																		 unsigned char *unSegData,
																		 unsigned char *resultData,
																		 int x, int y, int z,
																		 float averageWhiteIntensity, 
																		 float thresholdIntensity,
																		 float averageGrayIntensity){

  bool visualizationVMR_F=false;
  int choiceHeuristic = 2;  
  //-1=>only addition, 0=>only deletion, 1=> least # inverted voxels, 2=> least total damage (intensity-based heuristic)

  int i,j,k;
  unsigned char voxelIntensity;
	
  //Orientation shouldn't matter as long as it's returned in the same manner
  for (i=0;i<256;i++){
    for (j=0;j<256;j++){	
      for (k=0;k<256;k++){			
				if (i<x && j<y && k<z){
					posObj[i][j][k]=preSegData[k+j*z+i*z*y];
					if(posObj[i][j][k]!=0) posObj[i][j][k]=63;
					unsegVMRobj[i][j][k]=unSegData[k+j*z+i*z*y];
				}else{
					posObj[i][j][k]=0;
					unsegVMRobj[i][j][k]=0;
				}
      }	
    }
  }

  //PREPARATION
  fillFrameWithAir(posObj);
  determineBoxDimensions(posObj); //used for both normal AND inverse cutting!

  g_averageWhiteIntensity = averageWhiteIntensity;
  g_averageGrayIntensity = averageGrayIntensity;
  g_thresholdIntensity = thresholdIntensity;
  g_choiceHeuristic = choiceHeuristic;
  g_visualizationVMR_F = visualizationVMR_F;

  //progress indication
  nVoxIncludedInPosObj = 0;
  nVoxIncludedInNegObj = 0;

  //monitoring # volSelftouching checks
  nVolSelftouchingChecks = 0;
		
  //REMOVE ALL BRIDGES BY CUTTING THE INVERSE OBJECT'S RINGS (FILLING HOLES)
  showMessage("Initializing negative object...");
  initNegObj();
  showMessage("Beginning negative cuts (filling holes)...");
  if(!cutAllST(listOfNegativeCutPs, negObj)){
    showMessage("Error during negative cutting.");
  }

  //REMOVE ALL BRIDGES BY CUTTING THE OBJECT'S RINGS 
  showMessage("Beginning positive cuts...");
  if(!cutAllST(listOfPositiveCutPs, posObj)){
    showMessage("Error during positive cutting.");
  }
  showMessage("Finished positive cutting.");

  //ESTABLISH THE CORRESPONDENCE MAPPING BETWEEN THE TWO SETS OF CUTS
  psq<choiceC*> listOfChoicePs;

  showMessage("Establishing correspondence...");
  if(!establishCorrespondence(listOfPositiveCutPs, listOfNegativeCutPs, listOfChoicePs)){
    showMessage("Error during establishment of the correspondence between the cuts.");
  }
	
  // CHOOSE THE BETTER SOLUTION FOR EACH PAIR OF CORRESPONDING CUT SETS 
	// AND FINALLY DO THE BLOODY CUTTING
  showMessage("Now applying the cuts...");
  makeChanges(listOfChoicePs, posObj);
  showMessage("Changes made!"); //monitoring

  for (i=0;i<256;i++){
    for (j=0;j<256;j++){	
      for (k=0;k<256;k++){	
				if (i<x && j<y && k<z){
					voxelIntensity = posObj[i][j][k];
					if(voxelIntensity!=cidAdded && voxelIntensity!=cidRemoved 
						 && voxelIntensity!=cidUnchangedAir)
						if(voxelIntensity&128) //if in fluid
							voxelIntensity = cidUnchangedObj;
						else voxelIntensity = cidUnchangedAir;
					resultData[k+j*z+i*z*y] = voxelIntensity;
				}
      }
    }
  }
  return true;
}

// To make the code more ANSI compliant, change 'mexPrintf' to 'printf'
void CRemoveBridges::showMessage(string msg){
  mexPrintf("%s\n", msg.c_str());
  mexEvalString("pause(.001);"); // Let matlab flush the buffer
}
void CRemoveBridges::showMessage(int msgNum){
  mexPrintf("%d\n", msgNum);
  mexEvalString("pause(.001);"); // Let matlab flush the buffer
}
void CRemoveBridges::showMessage(double msgNum){
  mexPrintf("%f\n", msgNum);
  mexEvalString("pause(.001);"); // Let matlab flush the buffer
}

inline void CRemoveBridges::updateProgress(int newPercentProgress){
  if(newPercentProgress>percentProgress+1){
    mexPrintf("%d%% finished...\n", newPercentProgress);
    mexEvalString("pause(.001);"); // Let matlab flush the buffer
    percentProgress = newPercentProgress;
  }
}
