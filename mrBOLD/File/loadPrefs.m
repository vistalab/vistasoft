function vw = loadPrefs(vw)
%
% loadPrefs(vw)
%
% Loads UI settings in userPrefs file.  There's a separate
% userPrefs file for each view.
%
% loadPrefs.m
% djh, 1/19/98
% Modifications:
% djh, 4/99.  
% - Removed overlayClip.  
% - Added mapWindow.
% - Sets slice numbers for all 3 slice orientations
% ras, 02/04
% - expanded to load a bit more information (if previously saved):
%   1) The position of the vw figure on the screen
%   2) Color map settings for the different vw modes
%   3) ROI vw preference: outline vs. filled, selected vs. all vs. hide

pathStr=fullfile(viewDir(vw),'userPrefs.mat');
if exist(pathStr,'file');
    disp(['Loading user preferences: ',pathStr])
    load(pathStr);
else
    disp(['Could not find ',pathStr])
    return;
end

% select data type, scan
vw = selectDataType(vw, dataTypeName);
vw = setCurScan(vw, curScan);

% set corAnal vw params
vw = setCothresh(vw, cothresh);
vw = setPhWindow(vw, phWindow);

% load the map described by [mapName] if it exists
if exist('mapName', 'var')
	vw.mapName = mapName;
	mapPath = fullfile(dataDir(vw), [mapName '.mat']);
	if exist(mapPath, 'file')
		vw = loadParameterMap(vw, mapPath);
	end
end

try
	vw = setMapWindow(vw, mapWindow);
	vw = setDisplayMode(vw, displayMode);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ROI info                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('zoomBounds','var')
    vw.ui.zoom = zoomBounds;
end

if(~exist('filledPerimeter','var'))
    filledPerimeter=0;
end
vw.ui.filledPerimeter=filledPerimeter;

if(~exist('selRoiColor','var'))
    selRoiColor=[0 0 1];
end
vw.ui.selRoiColor=selRoiColor;


switch vw.viewType
    case 'Inplane'
        vw = viewSet(vw, 'curslice', curSlice);
        % check for montage size setting
        if exist('montageSize','var') && checkfields(vw,'ui','montageSize')
            vw = setSlider(vw, vw.ui.montageSize, montageSize, 0);
        end
    case {'Volume','Gray'}        
        for sliceOri = 1:3            
            setCurSliceOri(vw,sliceOri);
            %setCurSlice(vw,curSlices(sliceOri));
            vw = viewSet(vw, 'curslice', curSlices(sliceOri));
        end
        setCurSliceOri(vw,curSliceOri);
        %setCurSlice(vw,curSlice);
        vw = viewSet(vw, 'curslice', curSlice);
    case 'Flat'
        
        % The following two fields may not exist in older preference files
        if (~exist('rotations','var'))
            rotations=[0 0];
        end
        if (~exist('flipLR','var'))
            flipLR=[0 0];
        end
        
        vw = setFlatRotations(vw,rotations,flipLR);
        vw = viewSet(vw, 'curslice', curSlice);
		if curSlice < 3
	        setImageRotate(vw, rotations(curSlice)/(180/pi) );
		end
end

% the following info was saved only recently -- only load if available
if exist('anatMode','var')    vw.ui.anatMode = anatMode;      end
if exist('coMode','var')      vw.ui.coMode = coMode;          end
if exist('ampMode','var')     vw.ui.ampMode = ampMode;        end
if exist('phMode','var')      vw.ui.phMode = phMode;          end
if exist('mapMode','var')     vw.ui.mapMode = mapMode;        end
if exist('showROIs','var')    vw.ui.showROIs = showROIs;      end
if exist('roiDrawMethod','var'), vw.ui.roiDrawMethod = roiDrawMethod;  end
if exist('crosshairs','var')    
	vw.ui.crosshairs = crosshairs;  
	if crosshairs==1 && checkfields(vw, 'ui', 'xHairToggleHandle')
		set(vw.ui.xHairToggleHandle, 'Value', 1); % turn on
	end
end

if exist('winPos','var')
    set(vw.ui.windowHandle,'Units','Normalized','Position',winPos);
end

if exist('anatClip','var') 
    if isfield(vw.ui,'anatMin')
        setAnatClip(vw,anatClip);
    elseif isfield(vw.ui,'contrast')
        vw = viewSet(vw,'contrast',diff(anatClip));
    end
end

if exist('brightness','var') && isfield(vw.ui,'brightness')
    vw = viewSet(vw,'brightness',brightness);
end

vw = refreshScreen(vw);

disp('Loaded prefs');

return;
