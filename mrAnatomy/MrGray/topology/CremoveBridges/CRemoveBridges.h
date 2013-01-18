#include <string>
using namespace std;

//**********************************************************************
//general (P)eekable (S)tack/(Q)ueue class implemented as pointered list
//declaration
template<class C> class psqElement {
 public:
  C contentOfElement;
  psqElement<C>* next;
  
  psqElement(C aContentOfElement, psqElement<C>* n);
  psqElement();
  ~psqElement();
};

template<class C> class psq {
  psqElement<C>* first;
  psqElement<C>* last;
  psqElement<C>* current;
  int s; //size
  
 public:
  psq();
  ~psq();
  int size();
  
  bool stackpush(C coe);
  bool queuepush(C coe);
  bool pop(C& coe);
  
  bool peek(int i, C& contentOfElement);
  bool peekNext(C& contentOfElement);
  void resetPeek();
  psqElement<C>* firstPsqElementPRevealed();
};

//*****************************************
//special bridge removal class declarations

struct voxT{
	int x;
	int y;
	int z;
	voxT(int xx, int yy, int zz);
	voxT();
};

//cut description class declarations
class cutC{
public:
	psq<voxT> cutContour;
	psq<voxT> cutFilling;
	
	float damage;

	bool marked;

	cutC();
	~cutC();
};

//represents one choice
class choiceC{
public:
	int choiceI;

	psq<cutC*> listOfPosCutPs; //corresponding sets of pos. and neg. cuts
	float totalPosCutDamage;

	psq<cutC*> listOfNegCutPs;
	float totalNegCutDamage;

	choiceC();
	~choiceC();

};


//arrayFringeQueue
class arrayFringeQueueC{
	voxT** arrayOfArrays;
	int blockSize;
	int maxNblocks;
	int cPushBlock;
	int cPushPos;
	int cPopBlock;
	int cPopPos;

public:
	int size;
	arrayFringeQueueC(int blockSize, int maxNblocks);
	~arrayFringeQueueC();
	bool pop(voxT& vox);
	bool push(voxT vox);
};

// I tried to make these static const class vars, but Visual C doesn't like that.
#define cidUnchangedAir 0
#define cidUnchangedObj 225 //BVwhite
#define cidRemoved 236 //BVgray
#define cidAdded 245 //BVgreen
#define cidAlternative 226 //BVred-orange
#define surfaceFillingTimeProportion .08
#define choiceMakingTimeProportion .08
#define volFloodFillTimeProportion .84
class CRemoveBridges{
 public:
  //****************************************************
  //CONSTANTS & CONVENTIONS
  //air				0
  //outermost skin	1
  //innermost skin	0<x<63
  //object core		63
  //if currently in fringe: +=64 (second highest bit set)
  //if currently in fluid: +=128 (highest bit set)

  //COLOR ID CONSTANTS
/*   static const unsigned char cidUnchangedAir = 0; */
/*   static const unsigned char cidUnchangedObj = 225;//BVwhite */
/*   static const unsigned char cidRemoved = 236;//BVgray */
/*   static const unsigned char cidAdded = 245;//BVgreen */
/*   static const unsigned char cidAlternative = 226;//BVred-orange */

  // PUBLIC METHODS
  CRemoveBridges();
  ~CRemoveBridges();
  unsigned char remove(unsigned char *preSegData,
		       unsigned char *unSegData,
		       unsigned char *resultData,
		       int x,
		       int y,
		       int z,											   
		       float averageWhiteIntensity,
		       float thresholdIntensity,
		       float averageGrayIntensity);
  void showMessage(string msg);
  void showMessage(int msgNum);
  void showMessage(double msgNum);
  int round(double x){ if(x<0) return((int)(x-0.5)); else return((int)(x+0.5)); }
  inline void updateProgress(int newPercentProgress);
 private:
  unsigned char posObj[256][256][256];
  unsigned char negObj[256][256][256];
  unsigned char unsegVMRobj[256][256][256];
  unsigned char vmrHeaderBuffer[6];

  int pas[27][17];
  int eas[27][13];
  int sas[27][5];

  int maxX;
  int minX;
  int maxY;
  int minY;
  int maxZ;
  int minZ;

  string logFileS;

  psq<cutC*> listOfPositiveCutPs;
  psq<cutC*> listOfNegativeCutPs;

  //progress indication
  int nVoxInBlock;
  //# voxels of the positive object (including smaller separate components that will be discarded)
  int nVoxInPosObj;
  //# voxels of the NEGAtive object (EXcluding smaller separate components that will be discarded)
  int nVoxInNegObj; 
  int nVoxIncludedInPosObj, nVoxIncludedInNegObj;
  volatile int percentProgress;
/*   static const double surfaceFillingTimeProportion = .08; */
/*   static const double choiceMakingTimeProportion = .08; */
/*   static const double volFloodFillTimeProportion = .84; */

  //switches
  int g_choiceHeuristic; //choice heuristic (index)
  bool g_visualizationVMR_F;

  bool elaborateCutDescriptionF;

  //segmentation intensities
  float g_averageWhiteIntensity;
  float g_averageGrayIntensity;
  float g_thresholdIntensity;

  //monitoring
  int nVolSelftouchingChecks;

  // METHODS
  void initNegObj();
  void clearFringeNfluid(unsigned char obj[256][256][256]);
  void fillFrameWithAir(unsigned char obj[256][256][256]);
  void determineBoxDimensions(unsigned char obj[256][256][256]);
  voxT someLowestVox_normST(int zeroRingSkin, unsigned char obj[256][256][256]);
  void setFrameToCoreST(int zeroRingSkin, unsigned char obj[256][256][256]);
  int index(int x, int y, int z){return(x*9+y*3+z);};
  bool in3x3Block(int x, int y, int z){ if(x>=0 && x<3 && y>=0 && y<3 && z>=0 && z<3)return true; else return false; };
  void initPasEasNSas();
  bool surSelftouchingST(voxT centerVox, unsigned char obj[256][256][256]);
  inline bool inBlock(voxT vox);
  inline bool coreVoxAdjacentToST(int skin, voxT vox, unsigned char obj[256][256][256]);
  inline bool outerObjVoxST(voxT vox, unsigned char obj[256][256][256]);
  inline bool volSelftouchingST(voxT centerVox, unsigned char obj[256][256][256]);
  int surFloodfillST(char cSkin, voxT seedVox, unsigned char obj[256][256][256]);
  float deletionDamage(voxT vox);
  float additionDamage(voxT vox);
  bool uVolFloodfillST(voxT seedVox, psq<cutC*>& listOfCutPs, unsigned char obj[256][256][256]);
  bool existsCoreAdjacentToST(char skin, voxT& vox, unsigned char obj[256][256][256]);
  bool cutAllST(psq<cutC*>& listOfCutPs, unsigned char obj[256][256][256]);
  string CRemoveBridges::englishCutDescriptionElaboration(cutC* cutP);
  string englishCutDescription(cutC* cutP);
  string englishCutListDescription(psq<cutC*>& listOfCutPs);
  string englishChoiceListDescription(psq<choiceC*>& listOfChoicePs);
  bool writeLogFile(char *filespec);
  bool loadPresegVMR(char *filespec);
  bool loadUnsegVMR(char *filespec);
  bool saveBridgelessVMR(char *filespec);
  bool saveVisualizationVMR(char*filespec);
  void searchPartners_zerocrossing(cutC* sourceCutP, bool targetCutNegF, psq<cutC*>& sourceListOfCutPs, 
				   psq<cutC*>& targetListOfCutPs, choiceC* cChoiceP);
  void searchPartners(cutC* sourceCutP, bool sourceCutPosF, psq<cutC*>& sourceListOfCutPs, 
		      psq<cutC*>& targetListOfCutPs, choiceC* cChoiceP);
  bool establishCorrespondence(psq<cutC*>& listOfPosCutPs, psq<cutC*>& listOfNegCutPs, psq<choiceC*>& listOfChoicePs);
  float cutSetCost(choiceC* cChoiceP, bool posCutSetCostF);
  void setTheseCutsTo(psq<cutC*>& listOfCutPs, unsigned char newCid, bool logF, unsigned char obj[256][256][256]);
  void makeChanges(psq<choiceC*>& listOfChoicePs, unsigned char obj[256][256][256]);
};


//DEFINITIONS
//
// each voxel is bounded by 8 vertices and 12 edges.
//
// voxels CONNECTED (point-adjacent) to voxel v: voxels sharing at least one VERTEX with v (0d connexion)
// NEIGHBORING (edge-adjacent) voxels of v: voxels sharing at least one EDGE with v (1d connexion)
// ADJACENT (side-adjacent) voxels of v: voxels sharing one SIDE (2d connexion)
//
// a voxel has 6 adjacents, 18 neighbors and 26 connected voxels.



//VOLUME FILLING
//
// for each included voxel, all ADJACENT object voxels are added.
// (thus, the fluid doesn't flow into connected components unless they are adjacent.)
//
// the fluid volume-selftouches in a voxel v if the set C of fluid voxels CONNECTED to v
// contains a voxel not linked to all other voxels of C by ADJACENCY paths in C.



//SURFACE FILLING
// 
// for each included voxel, all neighboring surface voxels are added.
//  (leads to thinner skins - greater resolution - than including only adjacent voxels)
//
// the fluid surface-selftouches in a voxel v if the set C of fluid voxels CONNECTED to v
// contains a voxel not linked to all other voxels of C by NEIGHBORING paths in C.

