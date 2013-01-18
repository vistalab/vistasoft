function handles = dtiRoiSave(handles,varargin);
%
%  handles = dtiRoiSave(handles,options);
%
% Saves one or many ROIs.
%
% Options may include:
% * 'current' | 'selected' | 'all': save only the current ROI, allow
% user to select some ROIs to save, or save all the ROIs (default is
% current)
%
% * 'normalized': will warp the roi coords based on the currently loaded
% spatial normalization deformation field. (default is not  normalized)
% 
% HISTORY:
% 2005.01.27 RFD: rewrote the saving code so that all saves are done with
% one function.
% 2005.08.23 RFD: now lets user select a normalized coord space, if there
% are more than one. Also computes the inverse deformation for them, if
% needed.

versionNum = handles.versionNum;

fn = handles.defaultPath;
if(exist(fullfile(fn, 'ROIs'),'dir')) fn = fullfile(fn, 'ROIs', filesep); end
if isempty(handles.rois), warndlg('No ROIs'); return; end

% Parse options
if(~isempty(varargin))
    if(~isempty(strcmpi('all', varargin))) 
        saveMode = 3;
    elseif(~isempty(strcmpi('sel', varargin))) 
        saveMode = 2;
    else
        saveMode = 1;  
    end
    normFlag = isempty(strcmpi('norm', varargin));
end
if(normFlag)
    if(length(handles.t1NormParams)>1)
        [id,OK] = selector([1:length(handles.t1NormParams)], ...
        {handles.t1NormParams.name}, 'Select the coord space...');
        if(~OK) disp('user canceled.'); return; end
    else
        id = 1;
    end
    if(~isfield(handles.t1NormParams(id), 'name'))
        % in the old days, we didn't name the coord space.
        warning('no name associated with this coord space; using MNI.');
        handles.t1NormParams(id).name = 'MNI';
    end
    coordSpace = handles.t1NormParams(id).name;
    if(isfield(handles.t1NormParams(id),'sn'))
         xform = handles.t1NormParams(id);
        if(~isfield(xform,'deformX') || isempty(xform.deformX))
        	disp('Computing inverse deformation...');
            [xform.deformX, xform.deformY, xform.deformZ] = mrAnatInvertSn(xform.sn);
            handles.t1NormParams(id).deformX = xform.deformX;
            handles.t1NormParams(id).deformY = xform.deformY;
            handles.t1NormParams(id).deformZ = xform.deformZ;
        end
        % xform that goes from acpc space to the deformation field space. 
        xform.inMat = inv(xform.sn.VF.mat);
    else
        disp(['There is no xform specified- saving untransformed coords as "' coordSpace '".']);
        xform = [];
    end
else
    coordSpace = 'acpc';
    xform = [];
end

% Save 'em.
if(saveMode==1)
    roi = handles.rois(handles.curRoi);
    defaultName = [strrep(roi.name, ' ', '_') '.mat'];
    fn = fullfile(fn, defaultName);
    [f, p] = uiputfile({'*.mat';'*.*'}, ['Save ROIs "' roi.name '"...'], fn);
    if(isnumeric(f)), disp('Save current ROI canceled.'); return; end
    dtiWriteRoi(roi, fullfile(p, f), handles.versionNum, coordSpace, xform);
    disp('Current ROI saved.');
elseif(saveMode==2 || saveMode==3)
    p = uigetdir(fn, 'ROI directory');
    if isnumeric(p), disp('Save ROIs ... canceled.'), return; end
    if(saveMode==2)
        sList = dtiSelectROIs(handles,'Save ROIs');
        if isempty(sList), disp('Save ROIs ... canceled.'); return; end
    else
        sList = [1:length(handles.rois)];
    end
    rois = handles.rois(sList);
    for ii=1:length(rois)
        fName = dtiNameDefault(fullfile(p,rois(ii).name));
        dtiWriteRoi(rois(ii), fName, handles.versionNum, coordSpace, xform);
    end
    disp(sprintf('Saved %.0f ROIs.\n', length(rois)))
end
return;
