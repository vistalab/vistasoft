#include "vtkfilter.h"
#include "vtkWindowedSincPolyDataFilter.h"
#include "vtkSmoothPolyDataFilter.h"
#include "vtkCleanPolyData.h"
#include "vtkPolyData.h"
#include "vtkStripper.h"
#include "vtkDecimatePro.h"

CVTKFilter::CVTKFilter() {
    smooth_sinc_method = false;
    smooth_iterations = 20;
	smooth_relaxation = 0.1;
    smooth_feature_angle = 45;
    smooth_edge_angle = 15;
	smooth_boundary = true;
	smooth_feature_angle_smoothing = false;
    
    decimate_boudary_vertex_deletion = true;
    decimate_degree = 25;
    decimate_preserve_topology = true;
    decimate_reduction = 0.9;
    
    decimate_preserve_edges = false;
    decimate_iterations = 6;
    decimate_subiterations = 2;
    decimate_aspect_ratio = 25.0;
    decimate_initial_error = 0;
    decimate_error_increment = 0.005;
    decimate_maximum_error = 0.1;
}

CVTKFilter::~CVTKFilter() {
    
}

void CVTKFilter::UpdateParameters(mxArray* input)
{

	int number_of_fields, field_num;
	char** field_names;

	number_of_fields = mxGetNumberOfFields(input);
    field_names = new char* [number_of_fields];
    
	for (field_num = 0; field_num<number_of_fields; field_num++) {
		field_names[field_num] = (char *) mxGetFieldNameByNumber(input, field_num);

		if (!strcmp(field_names[field_num],"smooth_sinc_method"))
			smooth_sinc_method = (bool) mxGetScalar(mxGetField(input, 0, "smooth_sinc_method"));
			
		if (!strcmp(field_names[field_num],"smooth_iterations"))
			smooth_iterations = (int) mxGetScalar(mxGetField(input, 0, "smooth_iterations")); 

		if (!strcmp(field_names[field_num],"smooth_relaxation"))
			smooth_relaxation = (double) mxGetScalar(mxGetField(input, 0, "smooth_relaxation"));

		if (!strcmp(field_names[field_num],"smooth_feature_angle"))
			smooth_feature_angle = (double) mxGetScalar(mxGetField(input, 0, "smooth_feature_angle"));

		if (!strcmp(field_names[field_num],"smooth_edge_angle"))
			smooth_edge_angle = (double) mxGetScalar(mxGetField(input, 0, "smooth_edge_angle"));

		if (!strcmp(field_names[field_num],"smooth_boundary"))
			smooth_boundary = (bool) mxGetScalar(mxGetField(input, 0, "smooth_boundary"));

		if (!strcmp(field_names[field_num],"smooth_feature_angle_smoothing"))
			smooth_feature_angle_smoothing = (bool) mxGetScalar(mxGetField(input, 0, "smooth_feature_angle_smoothing"));

		if (!strcmp(field_names[field_num],"decimate_boudary_vertex_deletion"))
			decimate_boudary_vertex_deletion = (bool) mxGetScalar(mxGetField(input, 0, "decimate_boudary_vertex_deletion"));

		if (!strcmp(field_names[field_num],"decimate_degree"))
			decimate_degree = (int) mxGetScalar(mxGetField(input, 0, "decimate_degree"));

		if (!strcmp(field_names[field_num],"decimate_preserve_topology"))
			decimate_preserve_topology = (bool) mxGetScalar(mxGetField(input, 0, "decimate_preserve_topology"));

		if (!strcmp(field_names[field_num],"decimate_reduction"))
			decimate_reduction = (double) mxGetScalar(mxGetField(input, 0, "decimate_reduction"));

		if (!strcmp(field_names[field_num],"decimate_preserve_edges"))
			decimate_preserve_edges = (bool) mxGetScalar(mxGetField(input, 0, "decimate_preserve_edges"));

		if (!strcmp(field_names[field_num],"decimate_iterations"))
			decimate_iterations = (int) mxGetScalar(mxGetField(input, 0, "decimate_iterations"));

		if (!strcmp(field_names[field_num],"decimate_subiterations"))
			decimate_subiterations = (int) mxGetScalar(mxGetField(input, 0, "decimate_subiterations"));

		if (!strcmp(field_names[field_num],"decimate_aspect_ratio"))
			decimate_aspect_ratio = (double) mxGetScalar(mxGetField(input, 0, "decimate_aspect_ratio"));

	    if (!strcmp(field_names[field_num],"decimate_initial_error"))
			decimate_initial_error = (double) mxGetScalar(mxGetField(input, 0, "decimate_initial_error"));

		if (!strcmp(field_names[field_num],"decimate_error_increment"))
			decimate_error_increment = (double) mxGetScalar(mxGetField(input, 0, "decimate_error_increment"));

	    if (!strcmp(field_names[field_num],"decimate_maximum_error"))
			decimate_maximum_error = (double) mxGetScalar(mxGetField(input, 0, "decimate_maximum_error"));

    }

}

/*
bool CVTKFilter::DecimatePolyData(vtkPolyData* &pPD)
{
	vtkDecimatePro *pDecimate = vtkDecimatePro::New();
	//vtkDecimate *pDecimate = vtkDecimate::New();
	if (!pDecimate)
		return false;
	vtkPolyData *pOut = vtkPolyData::New();
	if (!pOut)
	{
		pDecimate->Delete();
		return false;
	}

	/////// taken from mrGray default settings
	//pDecimate->SetInitialFeatureAngle(30);
	//pDecimate->SetFeatureAngleIncrement(0);
	//pDecimate->SetMaximumFeatureAngle(60);
	pDecimate->SetBoundaryVertexDeletion(decimate_boudary_vertex_deletion);
	pDecimate->SetDegree(decimate_degree);
	pDecimate->SetPreserveTopology(decimate_preserve_topology);
	pDecimate->SetTargetReduction(decimate_reduction);

	//{ these methods exist in vtkDecimate only (not in vtkDecimatePro)
	//pDecimate->SetPreserveEdges(decimate_preserve_edges);
	//pDecimate->SetMaximumIterations(decimate_iterations);
	//pDecimate->SetMaximumSubIterations(decimate_subiterations);
	//pDecimate->SetAspectRatio(decimate_aspect_ratio);
	//pDecimate->SetInitialError(decimate_initial_error);
	//pDecimate->SetErrorIncrement(decimate_error_increment);
	//pDecimate->SetMaximumError(decimate_maximum_error);
	//}

	/////////////

//	pDecimate->AccumulateErrorOn();

	pDecimate->SetInput(pPD);

	pDecimate->Update();

	pOut->ShallowCopy(pDecimate->GetOutput());

	pDecimate->Delete();

	pPD->Delete();
	pPD = pOut;

	return true;
}*/

/*
bool CVTKFilter::Strippify(vtkPolyData* &pPD)
{
	//return true;//

	vtkStripper	*pStripper = vtkStripper::New();
	if (!pStripper)
		return false;
	
	vtkPolyData	*pOut = vtkPolyData::New();
	if (!pOut)
	{
		pStripper->Delete();
		return false;
	}

	pStripper->SetInput(pPD);
	pStripper->SetMaximumLength(100000);

	pStripper->Update();

	pOut->ShallowCopy(pStripper->GetOutput());

	pStripper->Delete();

	pPD->Delete();
	pPD = pOut;

	return true;
}*/


bool CVTKFilter::Smooth(vtkPolyData* &pPD)
{

	// 2003.09.24 RFD: Added option to use WindowedSinc smoothing.
	if(smooth_sinc_method){
		vtkWindowedSincPolyDataFilter *pSmooth = vtkWindowedSincPolyDataFilter::New();
		if (!pSmooth)
			return false;

		vtkPolyData	*pOut = vtkPolyData::New();
		if (!pOut){
			pSmooth->Delete();
			return false;
		}
		pSmooth->SetNumberOfIterations(smooth_iterations);
		pSmooth->SetPassBand(smooth_relaxation);
		pSmooth->SetFeatureAngle(smooth_feature_angle);
		pSmooth->SetEdgeAngle(smooth_edge_angle);
		pSmooth->SetBoundarySmoothing(smooth_boundary);
		pSmooth->SetFeatureEdgeSmoothing(smooth_feature_angle_smoothing);

		pSmooth->SetInput(pPD);

		pSmooth->Update();

		pOut->ShallowCopy(pSmooth->GetOutput());

		pSmooth->Delete();

		pPD->Delete();
		pPD = pOut;
	}else{
		vtkSmoothPolyDataFilter	*pSmooth = vtkSmoothPolyDataFilter::New();
		if (!pSmooth)
			return false;

		vtkPolyData	*pOut = vtkPolyData::New();
		if (!pOut){
			pSmooth->Delete();
			return false;
		}
		pSmooth->SetNumberOfIterations(smooth_iterations);
		pSmooth->SetRelaxationFactor(smooth_relaxation);
		pSmooth->SetFeatureAngle(smooth_feature_angle);
		pSmooth->SetEdgeAngle(smooth_edge_angle);
		pSmooth->SetBoundarySmoothing(smooth_boundary);
		pSmooth->SetFeatureEdgeSmoothing(smooth_feature_angle_smoothing);

		pSmooth->SetInput(pPD);

		pSmooth->Update();

		pOut->ShallowCopy(pSmooth->GetOutput());

		pSmooth->Delete();

		pPD->Delete();
		pPD = pOut;
	}
	return true;
}


bool CVTKFilter::BuildNormals(vtkPolyData* &pPD)
{
	vtkPolyDataNormals	*pNormalizer = vtkPolyDataNormals::New();
	if (!pNormalizer)
		return false;

	vtkPolyData	*pOut = vtkPolyData::New();
	if (!pOut)
	{
		pNormalizer->Delete();
		return false;
	}

	pNormalizer->ComputePointNormalsOn();
//	pNormalizer->ComputeCellNormalsOff();
	pNormalizer->SplittingOff();

	pNormalizer->SetInput(pPD);

	pNormalizer->Update();

	pOut->ShallowCopy(pNormalizer->GetOutput());

	pNormalizer->Delete();

	pPD->Delete();
	pPD = pOut;

	return true;
}


bool CVTKFilter::CleanPolyData(vtkPolyData* &pPD)
{
	vtkCleanPolyData	*pCleaner = vtkCleanPolyData::New();
	if (!pCleaner)
		return false;

	vtkPolyData	*pOut = vtkPolyData::New();
	if (!pOut)
	{
		pCleaner->Delete();
		return false;
	}

	pCleaner->ConvertPolysToLinesOff();
	pCleaner->ConvertStripsToPolysOff();
	pCleaner->PointMergingOn();

	pCleaner->SetInput(pPD);

	pCleaner->Update();

	pOut->ShallowCopy(pCleaner->GetOutput());

	pCleaner->Delete();

	pPD->Delete();
	pPD = pOut;

	return true;	
}

