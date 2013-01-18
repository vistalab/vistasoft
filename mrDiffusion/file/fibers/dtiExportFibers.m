function dtiExportFibers(handles,varargin)
%
%  dtiExportFibers(handles,options);
%
% Exports non-mrDiffusion fiber/path file formats. Currently supports: 
% 
% 1. MetroTrac (*.pdb) format
%
% Options may include:
% * 'current' | 'selected' | 'all': save only the current fiber group, allow
% user to select some groups to save, or save all the fibers (default is
% current)
%
% 
% HISTORY:
% 2007.06.15 AJS: wrote it.
%

fn = handles.defaultPath;
if(exist(fullfile(fn, 'fibers'),'dir')); fn = fullfile(fn, 'fibers', filesep); end
if isempty(handles.fiberGroups), warndlg('No fiber groups'); return; end

% Parse options
if(~isempty(varargin))
    if(~isempty(strmatch('all', lower(varargin)))); saveMode = 3;
    elseif(~isempty(strmatch('sel', lower(varargin)))); saveMode = 2;
    else saveMode = 1;  
    end
    normFlag = ~isempty(strmatch('norm', lower(varargin)));
end

if(normFlag)
    if(length(handles.t1NormParams)>1)
        [id,OK] = selector(1:length(handles.t1NormParams), ...
        {handles.t1NormParams.name}, 'Select the coord space...');
        if(~OK); disp('user canceled.'); return; end
    else
        id = 1;
    end
    if(~isfield(handles.t1NormParams(id), 'name'))
        % in the old days, we didn't name the coord space.
        warning('no name associated with this coord space; using MNI.'); %#ok<WNTAG>
        handles.t1NormParams(id).name = 'MNI';
    end
    %coordSpace = handles.t1NormParams(id).name;
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
    %coordSpace = 'acpc';
    xform = [];
end

% Save 'em.
if(saveMode==1)
    fg = handles.fiberGroups(handles.curFiberGroup);
    fn = fullfile(fn, [strrep(fg.name, ' ', '_') '.pdb']);
    [f, p] = uiputfile({'*.pdb';'*.*'}, ['Export Fibers "' fg.name '"...'], fn);
    if(isnumeric(f)), disp('Export current fibers canceled.'); return; end
    % For pdb format lets save out in ACPC space
    %mtrExportFibers(fg, fullfile(p, f), handles.xformToAcpc, xform);
    % Assume fiber groups are in AcPc space
    mtrExportFibers(fg, fullfile(p, f));
    disp('Current fibers exported.');
elseif(saveMode==2 || saveMode==3)
    p = uigetdir(fn, 'Fiber Group directory');
    if isnumeric(p), disp('Export FGs ... canceled.'), return; end
    if(saveMode==2)
        sList = dtiSelectFGs(handles,'Export FGs');
        if isempty(sList), disp('Export Fiber Groups ... canceled.'); return; end
    else
        sList = 1:length(handles.fiberGroups);
    end
    FGs = handles.fiberGroups(sList);
    for ii=1:length(FGs)
        fg = FGs(ii);
        fName = [strrep(fullfile(p,fg.name), ' ', '_') '.pdb'];
        mtrExportFibers(fg, fName, handles.xformToAcpc, xform);
    end
    disp(sprintf('Saved %.0f Fiber Groups.\n', length(FGs)))
end

return;

