function view = rmLoadAsWedgeRing(view, rmFile)
% load data maps from retModel file into mrVista interface fields
% ('Averages' dataType will be used) as if they were wedge and ring data.
% Wedge and Ring scans will be the first and second scans. 
% 
% co: variance explained
% ph: angle (first scan), eccenticity (second scan)
% map: eccentricity
% amp: pRF size
% 
% view = rmLoadAsWedgeRing(view, rmFile)
%
% 2008/3 KA: wrote it

global dataTYPES

if notDefined('view'),	view = getCurView;		end

% All ecc estimates larger than 'ecc_thre' will be truncated to 'ecc_thre'
ecc_thre = 12; 

%% set dataTYPE to 'Averages'
for i=1:size(dataTYPES,2)
    if strcmp(dataTYPES(i).name, 'Averages')
        view.curDataType = i;
    end
end

%% if no model loaded -- get the most recent model
if notDefined('rmFile')
    if sum(strcmp(fieldnames(view),'rm'))==0
        try
            view = rmSelect(view, 1, 'mostrecent');
        catch
            error('Couldn''t load a pRF Model.')
        end
    elseif viewGet(view, 'rmModelNum')==0
        try
            view = rmSelect(view, 1, 'mostrecent');
        catch
            error('Couldn''t load a pRF Model.')
        end
    end
else
    view = rmSelect(view, 0, rmFile);
end

%% load as if wedge data
view.curScan = 1;
view = rmLoad(view, 1, 'varexplained', 'co');
view = rmLoad(view, 1, 'eccentricity', 'map');
view = rmLoad(view, 1, 'polar-angle', 'ph');
view = rmLoad(view, 1, 'sigma', 'amp');

%% if a second scan exists, load as if ring data
try
    view.curScan = 2;
    view = rmLoad(view, 1, 'varexplained', 'co');
    view = rmLoad(view, 1, 'eccentricity', 'map');
    view.map{view.curScan}(find(view.map{view.curScan} > ecc_thre)) = ecc_thre;
    view.ph{view.curScan} = view.map{view.curScan}/ecc_thre*2*pi;
    view = rmLoad(view, 1, 'sigma', 'amp');
catch
   % ok. only one scan... 
end

view = setPhWindow(view, [0 2*pi]);
view = setCothresh(view, .1);
view.ui.ampMode.clipMode = [0 ecc_thre];
view.ui.ampMode = setColormap(view.ui.mapMode, 'hsvTbCmap');
view.ui.mapMode.clipMode = [0 ecc_thre];
view.ui.mapMode = setColormap(view.ui.mapMode, 'hsvTbCmap');
view.mapName = 'Eccentricity';
if ispc
	view.mapUnits = '�';
else
	view.mapUnits = 'degrees';
end

view.curScan = 1;
updateGlobal(view);
refreshScreen(view);

%% save data
% saveCorAnal(view,[],[],[],1);

return
