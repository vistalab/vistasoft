function view = loadCombinedROIs(view,files,name,select,color,roiDir)
%
% view = loadCombinedROIs(view,files,[name],[select],[color],[roiDir])
%
% Loads ROIs from several files, combines them into a new ROI,
% adds it to the ROIs field of view, and selects it.
%
% files: matrix of strings, e.g, ['V1L';'V1R'] that specify the
%        filenames.  This can also be a cell vector.
% name: name (string) for the combined ROI (default = first
%       string of files).
% select: if non-zero, chooses the new ROI as the selectedROI
%         (default=1).
% color: sets color for drawing the ROI.  Default is color of
%        first loaded ROI.  If none of the ROI files specify a color, 
%        uses 'b' as the default.
%
% djh, 1/24/98 
% dbr, 12/15/99  Modified to use absolute file spec based on mrSESSION.viewDir
%                field, or an optional rootDir input string.
% dbr, 1/00      Allowed use of cell arrays for files input; either row
%                or column vector is okay.
% djh, 2/21/2001 Changed rootDir to roiDir

if ~exist('roiDir', 'var')
  roiDir = viewDir(view);
end

if ~exist('name','var')
  if iscell(files)
    name=files{1};
  else
    name=files(1,:);
  end
end

if ~exist('select','var')
  select=1;
end

combinedROI.viewType = view.viewType;
combinedROI.name = name;
combinedROI.coords = [];
if iscell(files)
  nFiles = length(files);
else
  nFiles = size(files, 1);
end

for f=1:nFiles
  if iscell(files)
    filename=files{f};
  else
    filename=files(f,:);
  end
  pathStr = fullfile(roiDir,filename);
  if check4File(pathStr) 
    load(pathStr);
  else
    error([pathStr,' does not exist']);
  end
  combinedROI.coords = mergeCoords(combinedROI.coords,ROI.coords);
  % Set color (if it exists and if it is not already set).
  if (~exist('color','var') & isfield(ROI,'coords'))
    color=ROI.color;
  end
end

if exist('color','var')
  combinedROI.color=color;
end
if ~isfield(ROI,'color')
  ROI.color='b';
end

l = length(view.ROIs);
view.ROIs(l+1) = sortFields(combinedROI);

if select
  view = selectROI(view,length(view.ROIs));
end

% set the ROI popup menu
setROIPopup(view);
