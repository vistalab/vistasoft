function mv = mv_exportSelectivity(mv, saveFlag, threshold, conditions);
%
% mv = mv_exportSelectivity(mv, [saveFlag], [threshold], conditions);
%
% Export, from a MultiVoxel UI to a mrVista view,
% a  parameter map of selectivity indices for each voxel,
% this map is saved as Selectivity-ROI.mat
% a corresponding colormap is save SelectivityCmap.mat 
% which can be loaded from the Color Map UI
%
% Category indepdendent selecitivities range from 0-1 
% The color indicates both the selectivity and category preference
% Thus, selectivity values are mapped to: category+selectivity
% where category are integers ranging from 0:Ncats-1
%
%  A second map is saved as a corAnal
%  note that this will overwrite the default corAnal performed on these data
%  This map is used for thresholding the selectivity map
%  co field contains voxel reliability (note that cothres has values of 0-1
%  thus, all negative reliabilities are going to be thresholded by default)
%  ph contains category independent selectivities
%  The co and ph fields can used to threshold the selectivity maps
% 
% When loading a saved selectivity map need to load 3 files:
% File -> load Parmater Map-> Selectvity-ROIname
% File-> load CorAnal
% Color Map -> Parameter Map Mode -> Load colormap from file -> SelectivityCamp
%
% ras, 09/2005
% kgs 10/2005

if ieNotDefined('mv'), mv = get(gcf,'UserData'); end
if ~exist('threshold','var')
    threshold=0.1;
end
%%%%%check that a view exists
mrGlobals;
switch mv.roi.viewType
    case 'Inplane', view = getSelectedInplane;
    case 'Volume', view = getSelectedVolume;
    case 'Gray', view = getSelectedGray;
    case 'Flat', view = getSelectedFlat;
end
if isempty(view), error('No mrVista view opened.'); return; end    

% get relevant params about the view
mapdims = viewGet(view,'dataSize');
nScans = viewGet(view,'numScans');
scan = mv.params.scans(1);
    
%%%%%get amplitudes for selected conditions
whichConds = find(tc_selectedConds(mv));
whichConds = whichConds(whichConds>1)-1; % remove null
nConds = length(whichConds);

%%%%%compute selectivity index
[scaledSel sel]= mv_selectivity(mv, whichConds, threshold);

% plug in the values to the map volume:
mapvol = zeros(mapdims);
ind = roiIndices(view,mv.coords);
mapvol(ind) = scaledSel;

%%%%%get voxel reliabilities, map to co map
if ~isfield(mv,'wta'), mv=mv_reliability(mv,'plotFlag',0); end
covol = zeros(mapdims);
covol(ind) = sel;
% % hack: move to range 0:1 instead of -1:1 so cothres can apply to the
% % whole range and not only positive numbers
% covol = 0.5*ones(mapdims);
% covol(ind) = mv.wta.voxR/2+covol(ind); 

%%%%%map the reliabilityinto the ph map
phvol = zeros(mapdims);
% phvol(ind) = mod(sel, 1);
phvol(ind) = normalize(mv.wta.voxR, 0, 2*pi);


%%%%%create a color map
M = view.ui.mapMode;
colorsPerCond = floor(128/nConds);
M.numColors = colorsPerCond*nConds;
colors=[];
for i=1:nConds
    % make each condition have a gradient of colors up to
    % the full color specified by the color order
    col = mv.trials.condColors{whichConds(i)+1}; % full color
    for j = 1:colorsPerCond
        w = 0.3+ 0.5*(j-1)/colorsPerCond; % weight of color
        colors(end+1,:)=(w*col+ ((colorsPerCond-j+1)/(colorsPerCond))*[.7 .7 .7]);     
    end
end
M.cmap = [gray(M.numGrays); colors];
max(M.cmap)
M.clipMode = [0.01 nConds+0.02]; % set to manual clip mode

% save the color map
cmapPath = fullfile(dataDir(view),'SelectivityCmap.mat');
cmap = M.cmap(M.numGrays+1:end,:);
save(cmapPath,'cmap');
fprintf('Saved color map in %s\n',cmapPath);

%%%%%set in view
map = cell(1,nScans); co = cell(1,nScans); ph = cell(1,nScans);
mapName = sprintf('Selectivity_%s',mv.roi.name);
map{scan} = mapvol; co{scan} = covol; ph{scan} = phvol;
view.map = map; view.mapName = mapName;
view.co = co; view.ph = ph; view.amp=map;
view.ui.mapMode = M;
try 
    view=setParameterMap(view,map,mapName);
end
if saveFlag==1,
    saveParameterMap(view,[],1);
    saveCorAnal(view,1)
end
try
    refreshScreen(view);
catch
    return
end

% evaluate this in the workspace, so the view
% itself is updated
assignin('base','map',map);
assignin('base','co',co);
assignin('base','ph',ph);
assignin('base','tmp',M);

evalin('base',sprintf('%s=setParameterMap(%s,map,''%s'');',...
    view.name,view.name,mapName));
evalin('base',sprintf('%s=setDisplayMode(%s,''map'');',...
    view.name,view.name));
evalin('base',sprintf('%s.map = map;',view.name));
evalin('base',sprintf('%s.ui.mapMode=tmp;',view.name));
evalin('base',sprintf('%s.co=co;',view.name));
evalin('base',sprintf('%s.ph=ph;',view.name));
evalin('base',sprintf('%s=refreshScreen(%s);',view.name,view.name));

disp('Exported voxel selectivity to mrVista view.')

return
