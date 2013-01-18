function dtiFiberSave(handles,varargin);
%
%  dtiFiberSave(handles,options);
%
% Saves one or many fiber groups.
%
% Options may include:
% * 'current' | 'selected' | 'all': save only the current fiber group, allow
% user to select some groups to save, or save all the fibers (default is
% current)
%
% * 'normalized': will warp the fiber coords based on the currently loaded
% spatial normalization deformation field. (default is not  normalized)
% 
% Author: Wandell, Dougherty
% HISTORY:
% 2005.01.14 RFD: rewrote the saving code so that all saves are done with
% one function.

versionNum = handles.versionNum;

fn = handles.defaultPath;
if(exist(fullfile(fn, 'fibers'),'dir')) fn = fullfile(fn, 'fibers', filesep); end
if isempty(handles.fiberGroups), warndlg('No fiber groups'); return; end

% Parse options
if(~isempty(varargin))
    if(~isempty(strmatch('all', lower(varargin)))) saveMode = 3;
    elseif(~isempty(strmatch('sel', lower(varargin)))) saveMode = 2;
    else saveMode = 1;  end
    normFlag = ~isempty(strmatch('norm', lower(varargin)));
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
        if(~isfield(xform,'deformX')||isempty(xform.deformX))
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
    fg = handles.fiberGroups(handles.curFiberGroup);
    defaultName = [strrep(fg.name, ' ', '_') '.mat'];
    fn = fullfile(fn, [strrep(fg.name, ' ', '_') '.mat']);
    [f, p] = uiputfile({'*.mat';'*.*'}, ['Save Fibers "' fg.name '"...'], fn);
    if(isnumeric(f)), disp('Save current fibers canceled.'); return; end
    dtiWriteFiberGroup(fg, fullfile(p, f), handles.versionNum, coordSpace, xform);
    disp('Current fibers saved.');
elseif(saveMode==2 || saveMode==3)
    p = uigetdir(fn, 'Fiber Group directory');
    if isnumeric(p), disp('Save FGs ... canceled.'), return; end
    if(saveMode==2)
        sList = dtiSelectFGs(handles,'Save FGs');
        if isempty(sList), disp('Save Fiber Groups ... canceled.'); return; end
    else
        sList = [1:length(handles.fiberGroups)];
    end
    FGs = handles.fiberGroups(sList);
    for ii=1:length(FGs)
        fg = FGs(ii);
        fName = dtiNameDefault(fullfile(p,fg.name));
        dtiWriteFiberGroup(fg, fName, handles.versionNum, coordSpace, xform);
    end
    disp(sprintf('Saved %.0f Fiber Groups.\n', length(FGs)))
end
return;