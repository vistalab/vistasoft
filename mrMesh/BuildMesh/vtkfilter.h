#ifndef _VTKILTER_H_
#define _VTKILTER_H_

class CVTKFilter
{
public:
    
    CVTKFilter();
    virtual ~CVTKFilter();
    
	bool	DecimatePolyData(vtkPolyData* &pPD);
	bool	Strippify(vtkPolyData* &pPD);
	bool	Smooth(vtkPolyData* &pPD);
    bool	BuildNormals(vtkPolyData* &pPD);
	bool	CleanPolyData(vtkPolyData* &pPD);
	void	UpdateParameters(mxArray* input);
    
    bool smooth_sinc_method;
    int smooth_iterations;
	double	smooth_relaxation;
    double  smooth_feature_angle;
    double  smooth_edge_angle;
	bool smooth_boundary;
	bool	smooth_feature_angle_smoothing;
    
	bool decimate_boudary_vertex_deletion;
	int decimate_degree;
	bool decimate_preserve_topology;
	double decimate_reduction;

	//{ these methods exist in vtkDecimate only (not in vtkDecimatePro)
	bool decimate_preserve_edges;
	int decimate_iterations;
	int decimate_subiterations;
	double decimate_aspect_ratio;
	double decimate_initial_error;
	double decimate_error_increment;
	double decimate_maximum_error;


};

#endif //_VTKILTER_H_
