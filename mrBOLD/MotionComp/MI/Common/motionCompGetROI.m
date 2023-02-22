function ROI = motionCompGetROI(view,ROIname,resample)
%
%    gb 04/25/05
%
%    ROI = motionCompGetROI(view,ROIname,resample)
%
% Loads the ROI called ROIname. It looks first if it is loaded in the
% current Inplane. Then it looks in the directory HOMEDIR/Inplane/ROI
%
% Inputs:
%   - view: current Inplane view
%   - ROIname: string name of the ROI. It can also be number. In this case,
%   it will look for the name 'ROI' + the number. Example 3 -> 'ROI3'
%   - resample: The ROI is stored in the anatomy format which is twice
%   bigger than the functional data format. Set resample to 1 if you want
%   to have a ROI ready to apply on a functional data
%

% Initializes arguments and variables
global dataTYPES
curDataType = viewGet(view,'currentDataType');
curScan = viewGet(view,'currentScan');

% Returns a ROI full of ones if it does not exist
if ieNotDefined('ROIname')
    ROI = ones([sliceDims(view) numberSlices(view,curScan)]);
    return
end

% If ROIname is numeric, creates the new ROIname
if isnumeric(ROIname)
    ROIname = ['ROI' num2str(ROIname)];
end

if ieNotDefined('resample')
    resample = 1;
end

% Looks for the ROIname in the inplane view
n = length(view.ROIs);
curROI = 0;

for i = 1:n
    if isequal(view.ROIs(i).name,ROIname)
        curROI = i;
        break
    end
end

% If it has not been found, looks for the ROIname in the ROI directory
if curROI == 0
    files = dir(roiDir(view));
	loading = 0;
	for i = 3:length(files)
        curName = files(i).name;
        if isequal(curName(1:end - 4),ROIname)
            load(fullfile(roiDir(view),curName));
            loading = 1;
            break
        end
        
	end
	
    % If it did find it, sends an error
	if loading == 0
        error('The ROI is not defined')
    else
        coords = ROI.coords;
    end
       
else
    coords = view.ROIs(curROI).coords;
end

% Originally, the ROI is a set of three coordinates vectors belonging to the ROI.
% It has to convert it to a 3D volume.
scan = viewGet(view,'curScan');
size1 = sliceDims(view,scan);
size2 = size(view.anat);

ROI = zeros(size2);
    
for i = 1:size(coords,2)
    newCoords = coords(:,i)';
    ROI(newCoords(1),newCoords(2),newCoords(3)) = 1;
end

% Resample the ROI
if resample
    T = maketform('affine',[size1(2)/size2(2) 0 0; 0 size1(1)/size2(1) 0; 0 0 1]);
    ROI = imtransform(ROI,T,'nearest');
    ROI = [ROI,zeros(size(ROI,1),1,size(ROI,3));zeros(1,size(ROI,2) + 1,size(ROI,3))];
    ROI = ROI(1:size1(1),1:size1(2),1:size(ROI,3));
end

return