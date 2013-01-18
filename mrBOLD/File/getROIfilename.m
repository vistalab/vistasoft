function [filename ok] = getROIfilename(vw, local)
% gets file names of ROIs to load
%
%     filename = getROIfilename(vw, [local])
%
% INPUTS:
%	vw: mrVista view.
%
%	local: flag indicating whether to use the local ROI directory (e.g.,
%	'Gray/ROIs/') or the shared ROI directory (e.g., '3DAnatomy/ROIs').
%	[default: 1, local]
%
% ras, 2009: now this calls a much-improved dialog in roiDialog.
if notDefined('vw'),    vw = getCurView; end
if notDefined('local')
    local = 1; %isequal(vw.viewType, 'Inplane');
else
    % if local is defined AND if local ~=1
    if ~local,
        if ispref('VISTA', 'verbose') && getpref('VISTA', 'verbose')==1
            disp('Loading from shared ROI directory');
        end
    end
end

switch vw.viewType
    case 'Inplane'
        initDir = 'Inplane/ROIs';
        dirList = {'Inplane/ROIs'};
        
    case 'Volume'
        sharedDir = fullfile(getAnatomyPath, 'ROIs');
        if local==1
            initDir = 'Volume/ROIs';
        else
            initDir = sharedDir;
        end
        dirList = {sharedDir 'Volume/ROIs' 'Gray/ROIs'};
        
    case 'Gray'
        if (ispref('VISTA','defaultROIPath'))
            
            sharedDir = fullfile(getAnatomyPath, getpref('VISTA','defaultROIPath'));
        else
            sharedDir = fullfile(getAnatomyPath, 'ROIs');
        end
        if local==1
            initDir = 'Gray/ROIs';
        else
            initDir = sharedDir;
        end
        dirList = {sharedDir 'Volume/ROIs' 'Gray/ROIs'};
        
    case 'Flat'
        initDir = fullfile(vw.subdir, 'ROIs');
        dirList = {initDir};
        
    otherwise
        initDir = '';
        dirList = {};
end

[filename ok] = roiDialog(initDir, dirList);
if ~ok, filename = ''; end

return
