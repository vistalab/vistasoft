function savePrefs(vw)
%
% savePrefs(vw)
%
% Saves UI settings in userPrefs file.  There's a separate
% userPrefs file for each view.
%
% djh, 1/19/98

% Modifications:
%
% djh, 4/99.
% - Removed overlayClip.  
% - Added mapWindow.
% - Saves all slice numbers for all 3 slice orientations.
% bw, 12.08.00
% - replaced '/' with filesep
% ras, 2.11.04
% - expanded to save a bit more information:
%   1) The position of the vw figure on the screen
%   2) Color map settings for the different vw modes
%   3) ROI vw preference: outline vs. filled, selected vs. all vs. hide
% Ress, 8/05
% Fixed dimension-swap bug in saving of zoom field.
% ras, 07/06
% - if a mesh is open, saves the preferred mesh name (to expedite scripts
% which loop across subjects, displaying data on each subjects' mesh)

pathStr=fullfile(viewDir(vw),'userPrefs');

displayMode  = vw.ui.displayMode;    %#ok<*NASGU> 
cothresh     = viewGet(vw, 'cothresh');      
phWindow     = viewGet(vw, 'phaseWindow');   
mapWindow    = viewGet(vw, 'mapWindow');     
curScan      = viewGet(vw, 'curScan');       
curSlice     = viewGet(vw, 'curSlice');      
dataTypeName = viewGet(vw, 'dataTypeName');  
mapName      = viewGet(vw, 'mapName');       

% 01/05: trying to migrate to using 
% brightness/contrast, but be back-
% compatible
if isfield(vw.ui,'anatMin')
    anatClip = getAnatClip(vw);
    contrast = diff(anatClip);
    brightness = 0.5;
elseif isfield(vw.ui,'brightness')
    brightness = viewGet(vw,'brightness');
    contrast = viewGet(vw,'contrast');
    anatClip = [0 contrast];
end

% 05/05: try to record zoomBounds as well
if checkfields(vw,'ui','zoom')
    zoomBounds = vw.ui.zoom;
else
    dims = viewGet(vw,'Size');
    
    % NOTE: the axis command operates in image logical (x, y, z) ordering.
    % The dims command returns matlab-style (y, x, z) ordering, so we have
    % to flip these here.
    switch vw.viewType
        case {'Inplane','Flat'},
            zoomBounds = [1 dims(2) 1 dims(1)];
        case {'Volume','Gray'},
            zoomBounds = [1 dims(2); 1 dims(1); 1 dims(3)];
    end
end


% mode colormap info
anatMode    = viewGet(vw, 'anatmode');  
coMode      = viewGet(vw, 'coMode');    
ampMode     = viewGet(vw, 'ampMode');   
phMode      = viewGet(vw, 'phMode');    
mapMode     = viewGet(vw, 'mapMode');   

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ROI info                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
showROIs        = viewGet(vw, 'showROIs');      
roiDrawMethod   = viewGet(vw, 'roiDrawMethod'); 
if checkfields(vw,'ui','filledPerimeter')
    filledPerimeter = vw.ui.filledPerimeter;
else
    filledPerimeter = 0;
end

if checkfields(vw,'ui','selRoiColor')
    selRoiColor = viewGet(vw, 'selRoiColor');   
else
    selRoiColor = [1 1 1]; % white default
end
   

% window position info
set(vw.ui.windowHandle,'Units','Normalized');
winPos = get(vw.ui.windowHandle,'Position');


%%%%% Save the Preferences
switch vw.viewType
case 'Inplane'
    if checkfields(vw,'ui','montageSize')
        % record montage size
        montageSize = get(vw.ui.montageSize.sliderHandle,'Value');
    else
        montageSize = 1;
    end
    
	save(pathStr, 'displayMode', 'cothresh', 'phWindow', 'mapWindow', ...
		 'mapName', 'anatClip', 'curScan', 'curSlice', 'dataTypeName', ...
		 'anatMode', 'coMode', 'ampMode', 'phMode', 'mapMode', ...
		 'brightness', 'contrast', 'showROIs', 'winPos', ...
         'zoomBounds', 'montageSize', 'filledPerimeter', 'selRoiColor', ...
         'roiDrawMethod');
    
    
case {'Volume','Gray'}
	curSlices = zeros(1,3);
	for sliceOri = 1:3
		curSlices(sliceOri) = ...
			str2num(get(vw.ui.sliceNumFields(sliceOri),'String'));
	end
	curSliceOri = getCurSliceOri(vw);
	
	if checkfields(vw, 'ui', 'crosshairs')
		crosshairs = vw.ui.crosshairs;
	else
		crosshairs = 0;
	end
	
	save(pathStr,'displayMode','cothresh','phWindow', 'mapName', ...
		 'mapWindow', 'anatClip', 'curScan', 'curSlice', 'dataTypeName', ...
		'curSlices', 'curSliceOri', 'anatMode', 'coMode', 'ampMode', ...
		'phMode', 'mapMode', 'showROIs', 'winPos', 'zoomBounds', ...
        'crosshairs', 'filledPerimeter', 'selRoiColor', 'roiDrawMethod');
    
    % mesh info: if a mesh is open
    if isfield(vw, 'mesh') && ~isempty(vw.mesh)
        meshName = vw.mesh{end}.name;
        meshPath = vw.mesh{end}.path;
        save(pathStr, 'meshName', 'meshPath', '-append');
    end
    
        
case 'Flat'
   
    if (~isfield(vw.ui,'filledPerimeter'))
        vw.ui.filledPerimeter=1;
    end
    

    % Also save rotation , LR flip 
    [rotations,flipLR]=getFlatRotations(vw);
    
    save(pathStr,'displayMode', 'cothresh', 'phWindow', 'mapWindow', ...
		'mapName','anatClip', 'curScan', 'curSlice', 'dataTypeName', ...
		'rotations', 'flipLR','filledPerimeter', 'anatMode', 'coMode', ...
		'ampMode', 'phMode', 'mapMode', 'showROIs', 'winPos', ...
        'zoomBounds', 'selRoiColor', 'roiDrawMethod');
end
disp('Saved preferences');

return;

