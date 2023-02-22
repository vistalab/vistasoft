function ROI = motionCompSaveROI(view,ROI,ROIname,resample)
%
%    gb 05/14/05
%
%    ROI = motionCompSaveROI(view,ROI,ROIname,resample)
%
% Stores the ROI into the directory HOMEDIR/Inplane/ROI with the name
% ROIname. 
%
% Inputs:
%   - view: current Inplane view
%   - ROIname: string name of the ROI.
%   - resample: The ROI is stored in the anatomy format which is twice
%   bigger than the functional data format. Set resample to 1 if you are
%   saving a ROI having the size of the functional data.

% Initializes arguments and variables
global dataTYPES
curDataType = viewGet(view,'currentDataType');
curScan = viewGet(view,'currentScan');

if ieNotDefined('ROIname')
    ROIname = 'ROInoname';
end

if ieNotDefined('resample')
    resample = 1;
end

scan = viewGet(view,'curScan');

% Resamples the ROI if needed
if resample
    size1 = sliceDims(view,scan);
    size2 = size(view.anat);
    T = maketform('affine',[size2(2)/size1(2) 0 0; 0 size2(1)/size1(1) 0; 0 0 1]);
	
    ROI = imtransform(ROI,T,'nearest');
    ROI = [zeros(1,size(ROI,2) + 1,size(ROI,3));zeros(size(ROI,1),1,size(ROI,3)),ROI];
        
    nVoxels = size2(1:2);
else
    nVoxels = sliceDims(view,scan);
end

% Transforms it to the storage format which is a set of 3-coordinate
% vectors belonging to the ROI.
roiIndex = find(ROI)' - 1;
ROIz = floor(roiIndex/prod(nVoxels));
roiIndex = rem(roiIndex,prod(nVoxels));
ROIy = floor(roiIndex/nVoxels(1));
ROIx = rem(roiIndex,nVoxels(1));

ROIx = ROIx + 1;
ROIy = ROIy + 1;
ROIz = ROIz + 1;
ROI = [ROIx;ROIy;ROIz];

% Saves the ROI
pathStr = roiDir(view);
pathStr = fullfile(pathStr,[ROIname '.mat']);
ROI = struct('color','b','coords',ROI,'name',ROIname,'viewType','Inplane');
save(pathStr,'ROI');