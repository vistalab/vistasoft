#include "nifti1_io.h"

#ifdef _WINDOWS_
#define strcasecmp(a,b) strcmp((a),(b))
#endif

/* We translate the NIFTI codes into human-readable strings. */ 

/* *** TO DO: translate intent_code */

const char *getNiftiUnitStr(int niftiCode){
	const char *str;
	switch(niftiCode){
	case NIFTI_UNITS_UNKNOWN: str = "unknown"; break;
	case NIFTI_UNITS_METER:   str = "meter"; break;
	case NIFTI_UNITS_MM:      str = "mm"; break;
	case NIFTI_UNITS_MICRON:  str = "micron"; break;
	case NIFTI_UNITS_SEC:     str = "sec"; break;
	case NIFTI_UNITS_MSEC:    str = "msec"; break;
	case NIFTI_UNITS_USEC:    str = "usec"; break;
	case NIFTI_UNITS_HZ:      str = "hz"; break;
	case NIFTI_UNITS_PPM:     str = "ppm"; break;
	case NIFTI_UNITS_RADS:    str = "rads"; break;
	default:                  str = "unknown"; break;
	}
	return(str);
}

const char *getNiftiUnitStrOptions(){
	const char *str = "unknown,meter,mm,micron,sec,msec,usec,hz,ppm,rads,unknown";
	return(str);
}

int getNiftiUnitCode(char *str){
	int code;
	if(strcasecmp(str,"meter")==0) code=NIFTI_UNITS_METER;
	else if(strcasecmp(str,"mm")==0) code=NIFTI_UNITS_MM;
	else if(strcasecmp(str,"mm")==0) code=NIFTI_UNITS_MM;
	else if(strcasecmp(str,"micron")==0) code=NIFTI_UNITS_MICRON;
	else if(strcasecmp(str,"sec")==0) code=NIFTI_UNITS_SEC;
	else if(strcasecmp(str,"msec")==0) code=NIFTI_UNITS_MSEC;
	else if(strcasecmp(str,"usec")==0) code=NIFTI_UNITS_USEC;
	else if(strcasecmp(str,"hz")==0) code=NIFTI_UNITS_HZ;
	else if(strcasecmp(str,"ppm")==0) code=NIFTI_UNITS_PPM;
	else if(strcasecmp(str,"rads")==0) code=NIFTI_UNITS_RADS;
	else code=NIFTI_UNITS_UNKNOWN;
	return(code);
}

/* 
 * This is here because calling mexErrMsgTxt causes matlabr14 to crash.
 * Probably has something to do with the fact that mexErrMsgTxt tries to
 * free any allocated memory before aborting. There are some bug reports
 * suggesting that the cause of this is using a different version of glibc 
 * and/or gcc for the mex file than that used to build matlab. Hopefully,
 * they will fix it, because the code below might leak memory if we allocate 
 * stuff before calling this.
 */
#define myErrMsg(msg){ mexPrintf("\n\n"); mexPrintf(msg); mexPrintf("\n\n"); return; }
