function [vw, status, forceSave] = saveROI(vw, ROI, local, forceSave)
%
% [view, status, forceSave] = saveROI([view=cur view], [ROI='selected'], [local], [forceSave=0])
%
% Saves ROI to a file.
%
% INPUTS:
%   vw: mrVista view. Finds current view if omitted.
%
%   ROI: ROI structure, or index into the ROI structure in the view. 
%   If this the string 'selected' the view's selected ROI to be saved. 
%   [This is the default behavior if the ROI argument is omitted.]
%
% local: flag to save ROI in a local directory to the view (e.g.,
% 'Volume/ROIs'), or a shared directory (e.g., relative to the
% anatomy directory -- use "setpref('VISTA', 'defaultROIPath')" to 
% set this directory.)  [For inplanes, defaults to 1, save locally. 
% for other views, defaults to 0, saves in shared directory.]
%
% forceSave: if set to 0, if the ROI file exists, will ask the user if they
% want to save over the existing file. If 1, will save over existing files
% without asking. Useful for scripting. [Defaults to 0].
%
% OUTPUTS:
%   vw    : Modified view (e.g, Inplane ...).
%   status: 0 if the ROI saving was aborted. This is used when calling this
%           repeatedly (see 'saveAllROIs'), if the file exists and the
%           user selects 'Cancel'.
%   forceSave: modified forceSave flag, if the file exists, and the user
%           wants to bypass the dialog for future files. (again, see 
%           'saveAllROIs'.)
%
% Example:  saveROI(INPLANE{1});
%
% See also:
%    The roi management is a mess.  This should be roiSave, but there is
%    another roiSave.  All the roi management routines have different names
%    and different behavior.  Sigh.
%
% Vistasoft Team
%
% djh, 1/24/98
% gmb, 4/25/98 added dialog box
% ARW 10/06/05 : Added default ROI path option
% (see also roiDir)
% ras 07/06: added forceSave flag.
% ras 10/06: ROI selection defaults to 'selected'; can enter ROI indices.
% ras 11/06: offers option to save over all, returning modified forceSave
% flag. (Very helpful when saving a lot of ROIs that you want to update.)

if notDefined('vw'),        vw = getCurView;        end
if notDefined('forceSave'), forceSave = 0;          end
if notDefined('ROI'),       ROI = 'selected';       end
if notDefined('local'),     local = isequal(vw.viewType, 'Inplane'); end

status = 0;
verbose = prefsVerboseCheck;

% disambiguate the ROI specification
if isnumeric(ROI), ROI = tc_roiStruct(vw, ROI); end

if ischar(ROI) && isequal(lower(ROI), 'selected')
    ROI = vw.ROIs( vw.selectedROI );
end

if isfield(ROI, 'roiVertInds')
    ROI = rmfield(ROI,'roiVertInds');
end 

if isempty(ROI.coords) && forceSave==0
    q = sprintf('Save empty ROI %s?', ROI.name);
    confirm = questdlg(q, mfilename, 'Yes', 'No', 'No');
    if ~isequal(confirm, 'Yes'), disp('ROI not saved.'); return; end
end

% The method of saving the ROI starts here
% First we make sure we add a .mat extension. Matlab does this most of
% the times but not always, for example if your name contains a '.'.
% It still saves the file but without '.mat' and consequently cannot load it.
[~,~,ext]=fileparts(ROI.name);
if ~strcmp(ext,'.mat'), ROIname = [ROI.name '.mat'];
else                    ROIname = ROI.name;     end;

pathStr = fullfile(roiDir(vw,local), ROIname);

if check4File(pathStr) && forceSave==0
    q = sprintf('ROI %s already exists.  Overwrite?', ROI.name);
    saveFlag = questdlg(q, 'Save ROI', 'Yes', 'No', 'Yes To All', 'No');
else
    saveFlag = 'Yes';
end

switch saveFlag
    case 'Yes'
        if verbose,
            fprintf('Saving ROI "%s" in %s. \n', ROI.name, fileparts(pathStr));        
        end
        save(pathStr,'ROI');
        status = 1;
        
    case 'No'
        if verbose,  fprintf('ROI %s not saved.', ROI.name);    end
        status = 1;     % not saved, but keep going if saving many ROIs
        
    case 'Yes To All'
        if verbose,     disp('Force-Saving all ROIs...');       end
        fprintf('Saving ROI "%s" in %s. \n', ROI.name, fileparts(pathStr));        
        forceSave = 1;
        status = 1;
        
    case 'Cancel'
        if verbose,  disp('ROI Saving Aborted.');               end
end

return;
