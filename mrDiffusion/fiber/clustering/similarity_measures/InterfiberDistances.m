function distmsr =  InterfiberDistances(fibergroup1, varargin)
%Usage examples
%function distmsr =  InterfiberDistances(fibergroup1, fibergroup2, npoints, method)
%function distmsr =  InterfiberDistances(fibergroup1, npoints, method)

%Compute interfiber distances among fibers in 2 sets of fibers (or with itself, if only one set of fibers is supplied). Parameter npoints is the number of points for
%approximating a fiber by spline.
%InterfiberAverageDistance(curve1, curve2), curves are stored as fg.fibers.
%method='ZhangDistance' the metric is described in Zhang et al. (2003) IEEE
%Transactions on Vizualization and Computer Graphics 9(4) 
%method='pairwise_dist' the distance between fibers is the average distance
%between corresponding sets of points; order of points is checked to
%control for mirror reflections
%method='point2curve' =>compute average minimal point-to-curve distance.
%method='point2curveStd' =>compute stdev minimal point-to-curve distance.
%method='frenet'=>compute average Frobenius norm between matrices with
%frenet parameters (speed, curvature, torsion) defined at each node for each curve
%ER 12/2007
%ER 09/2009 cleaned up 'ZhangDistance' method option

nfibers1=size(fibergroup1, 1);

if (nargin > 3)
    fibergroup2=varargin{1};
    npoints=varargin{2};
    method=varargin{3};
    samegroupflag=0;
    nfibers2=size(fibergroup2, 1);
else %Second fiber grp is not supplied
    samegroupflag=1;
    npoints=varargin{1};
    method=varargin{2};
end

curves1=zeros(3, npoints, nfibers1);
%1. Resample fibers in Fiberr Group 1 using splines
for i=1:nfibers1
    curves1(:, :, i)=dtiFiberResample(fibergroup1{i}, npoints);
end
display('B-splines for fiber grp1 computed; fibers resampled');

if samegroupflag==1
    curves2=curves1;
else
    curves2=zeros(3, npoints, nfibers2);
    
    for i=1:nfibers2
        curves2(:, :, i)=dtiFiberResample(fibergroup2{i}, npoints);
    end
    display('B-splines for fiber grp2 computed; fibers resampled');
end


%3. Compute distance
distmsr=zeros(size(curves1, 3), size(curves2, 3));

switch method
    
    case 'point2curve'
        
        
        for i=1:size(curves1, 3)
            for j=1:size(curves2, 3)
                
                distmsr(i, j)=InterfiberAveragePoint2CurveDistance(curves1(:, :, i), curves2(:, :, j));
                
            end
            %distmsr matrix does NOT have to be symmetric
        end
     
    case 'point2curveStd'
       
        
        for i=1:size(curves1, 3)
            for j=1:size(curves2, 3)
                       
                [a, distmsr(i, j)]=InterfiberAveragePoint2CurveDistance(curves1(:, :, i), curves2(:, :, j));
                
            end
            %distmsr matrix does NOT have to be symmetric
        end
        
    case 'ZhangDistance'
                Tt = inputdlg('Pairs of points in two curves which are closer than Tt (mm) are not considered when computing the distance between fibers','Provide threshold Tt',1,{'1'});

        for i=1:size(curves1, 3)
            for j=1:size(curves2, 3)
                distmsr(i, j)=InterfiberZhangDistance(curves1(:, :, i), curves2(:, :, j), Tt{1});
            end
        end
     
        
    case 'pairwise_dist',
        distmsr=intercurve_dist_pointwise(curves1, curves2, samegroupflag);
        
    case 'frenet',
        distmsr=dtiFrenetDistance(curves1, curves2, samegroupflag);
        
    otherwise,
        display('Only methods *pairwise_dist*, *ZhangDistance*, *frenet*, *point2curveStd* and *point2curve* are supported');
end

