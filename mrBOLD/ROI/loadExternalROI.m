function view = loadExternalROI(view, filename);
% view = loadExternalROI(view, [filename or filenames]);
%
% Loads an ROI from another session (providing a graphical prompt if the
% path is not entered as an argument). Can loop through multiple files if
% provided as a cell array of strings.
%
% Only allows transferring through gray/volume views -- possibly Flat views
% in the future. Loading from another session's inplane is clearly out
% (No way to figure out corresponding voxels in the two prescriptions).
%
% Will do soon but haven't implemented yet: for gray/volume views, check
% that the vANATOMYPATH for the two sessions are the same, or else
% warn/error.
%
% 02/04 ras.
% (NOTE: I had to include some redundant code here rather than call
% loadROI, which would be more elegant. This is b/c loadROI has the
% implicit assumption that you load everything relative to the roiDir path,
% which is not always true. It would be better to just change loadROI, but
% I didn't want to mess things up. -ras)
% 07/06 ras: can load multiple files at once.
% 09/2008 DY: remove command that forces ROI colors to be white. We often
% save our ROIs to be particular different colors for a reason and don't
% want them to become homogeneously colored just because we are loading
% them from a file. 

global HOMEDIR

if ~(isequal(view.viewType,'Volume') | isequal(view.viewType,'Gray') | isequal(view.viewType,'Flat'))
    error('Sorry, only Volume/Gray views can do this.');
end

if ~exist('filename','var')
    [fname pth] = myUiGetFile(HOMEDIR, '*.mat', 'Choose an ROI file(s)...', ...
        'MultiSelect', 'on');
    
    if iscell(fname)
        for i = 1:length(fname)
            filename{i} = fullfile(pth, fname{i});
        end
    else
        filename = fullfile(pth, fname);
    end
end

if iscell(filename) % iterate through multiple files
    for i = 1:length(filename)
        view = loadExternalROI(view, filename{i});
    end
    return
end

if check4File(filename) %changed from check4file to capital F (BZL)
    disp(['loading ',filename]);
    load(filename);

    % Coerce to current format with viewType instead of viewName
    if isfield(ROI,'viewName')
        ROI = rmfield(ROI,'viewName');
        ROI.viewType = view.viewType;
    end

    % let's use a white color to designate imported ROIs
    %ROI.color='w';

    view = addROI(view,ROI,1);

else
    warning([filename,' does not exist']);
end

return