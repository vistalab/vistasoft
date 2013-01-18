function view = mv_makeRoi(mv,roiName,saveFlag);
%
% view = mv_makeRoi([mv],[roiName],[saveFlag]);
%
% Take the set of voxels specified by a multi voxel
% UI and create a new mrVista ROI.
%
% This can be useful b/c some multi-voxel analyses
% (such as removing outliers or reliability analyses)
% can identify subsets of voxels within the current
% ROI, which the user may want to further analyze. 
%
% The new ROI will be placed in the currently selected
% view of the same type that the ROI coords are defined
% in. This information is produced when the MVUI is 
% created. For instance, an ROI launched from a Gray
% view will create a gray ROI. If no selected view
% of that type is found, it will save the ROI in the
% relevant roiDir. This overrides the saveFlag below.
%
% saveFlag is a flag to save the newly-produced ROI. 
% It defaults to 1. 
%
% If both roiName and saveFlag are omitted, a dialog
% pops up.
%
% ras, 05/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('roiName') 
    % dialog
    inpt(1).fieldName = 'roiName';
    inpt(1).style = 'edit'; 
    inpt(1).string = 'New ROI Name:';
    inpt(1).value = [mv.roi.name 'New'];
    
    inpt(2).fieldName = 'saveFlag';
    inpt(2).style = 'checkbox'; 
    inpt(2).string = 'Save ROI in RoiDir';
    inpt(2).value = 1;

    resp = generalDialog(inpt,'MultiVoxel UI -> mrVista ROI');
    
    roiName = resp.roiName;
    saveFlag = resp.saveFlag;
end

if ieNotDefined('saveFlag')
    saveFlag = 1;
end

% build new roi
roi.color = mv.roi.color;
roi.coords = mv.coords;
roi.name = roiName;
roi.viewType = mv.roi.viewType;

% get mrVista view
fn = sprintf('getSelected%s',roi.viewType);
view = eval(fn);
if isempty(view)
    % no selected view of the proper type -- make
    % a hidden one and save it
    saveFlag = 1;
    mrGlobals
    loadSession
    fn = sprintf('initHidden%s',roi.viewType);
    view = eval(fn);
end
% evaluate this in the workspace, so the view
% itself is updated
assignin('base','roi',roi);
cmd = sprintf('%s = addROI(%s,roi);',view.name,view.name);
evalin('base',cmd);

% save if selected
if saveFlag==1
    saveROI(view,roi);
end

return


