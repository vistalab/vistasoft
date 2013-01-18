function flattenFromROI(view, ROI)
% Initiates the mrFlatMesh GUI, filling in some fields
%
%  flattenFromROI(view, ROI)
%
% Wrapper for mrFlatMesh GUI. Opens the GUI, filling in some
% default starting values. Uses the center of mass of the specified
% ROI as the start point.
%
% GLOBALS: uses mrSESSION fields to initialize the mrFlatMesh GUI.
%
% Example:
%   flattenFromROI(VOLUME{1});    % Uses selected (current) ROI
%
% HISTORY:
% 2002.03.04 RFD (bob@white.stanford.edu): wrote it
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH
% 2002.07.19 RFD: cleaned up default filenames a bit
% 2006.02.05 MMS: made it work with ROIs with only one coordinate

mrGlobals

switch view.viewType
    case 'Gray'
        leftGrayPath  = view.leftPath;
        rightGrayPath = view.rightPath;
    otherwise
        error([mfilename,': unsupported view type "',view.viewType,'".']);
end

if(~exist('ROI','var'))
    if(view.selectedROI>0)
        ROI = view.ROIs(view.selectedROI);
    else
        myErrorDlg('No ROI selected');
        return;
    end
end

mmPerPixXYZ = readVolAnatHeader(vANATOMYPATH);

startXYZ = round(mean(ROI.coords',1)');
startXYZ = [startXYZ(2);startXYZ(1);startXYZ(3)];

% Now how do we find which hemisphere this coord belongs to?
hemi = viewGet(view, 'roihemi', ROI.coords);
if isempty('hemi'), hemi = 'left'; end;

if strcmpi('hemi', 'left')
    grayPath = fullfile(leftGrayPath,'');
else
    grayPath = fullfile(rightGrayPath,'');
end


[grayPathDir,grayPathFileName] = fileparts(grayPath);
if(exist(grayPath)~=2)
    if(exist(grayPathDir,'dir'))
        % at least get them close
        grayPath = grayPathDir;
    else
        grayPath = '';
        grayPathDir = '';
    end
end

% If the Gray coords are saved in the project as 'coords.mat', then use
% this to get the gray graph
coordsFile = fullfile(HOMEDIR, 'Gray', 'coords.mat');
if exist(coordsFile, 'file'),
    grayPath = coordsFile; 
end

% Try to guess the mesh file path
[p f e] = fileparts(leftGrayPath);

% if the gray path is a nifti class file, then we use this and not a mesh
if strcmpi(e, '.gz')
    if strcmpi('hemi', 'left')
        meshPath = fullfile(leftGrayPath,'');
    else
        meshPath = fullfile(rightGrayPath,'');
    end
else
    % otherwise we look for a mesh
    subDirs = {'','3dMeshes','3DMeshes','3Dmeshes'};
    extensions = {'.MrM','.mrm','.Mrm','.MRm','.MRM', 'nii.gz'};
    meshPath = grayPathDir;
    for ii=1:length(subDirs)
        for jj=1:length(extensions)
            if(exist(fullfile(grayPathDir,subDirs{ii},[grayPathFileName,extensions{jj}]))==2)
                meshPath = fullfile(grayPathDir,subDirs{ii},[grayPathFileName,extensions{jj}]);
                break;
            end
        end
    end
end
ts = now;
saveFileName = ['unfold_',datestr(ts,'mm'),datestr(ts, 'dd'),datestr(ts,'yy')];
if(exist(fullfile(grayPathDir,'Unfolds'), 'dir'))
    savePath = fullfile(grayPathDir, 'Unfolds', saveFileName);
else
    savePath = fullfile(grayPathDir, saveFileName);
end

unfoldRadiusMM = 60;

disp('calling mrFlatMesh...');

mrFlatMesh({'grayPath', grayPath, ...
    'meshPath', meshPath, ...
    'savePath', savePath, ...
    'scaleXYZ', mmPerPixXYZ , ...
    'startXYZ', startXYZ, ...
    'unfoldRadiusMM', unfoldRadiusMM, ...
    'hemi', hemi});

return;
