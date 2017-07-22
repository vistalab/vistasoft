function view = er_selectivityMap(view, roi, scans, dt, conditions, threshold);
%
% view = er_selectivityMap(<view=cur view>,  <roi=selected>, <scans=scan group>, ...
%                          <dt=cur dt>, <conditions=all>, <threshold=0.1>);
%
% Export a map showing the selectivity of each voxel to its preferred 
% condition. 
%
% Selectivity is defined as:
%   sel = (max - nonmax) / (max + abs(nonmax))
% where [max] is the amplitude of response to the "preferred" condition --
% by definition, the condition which produced the maximal response;
% [nonmax] is the set of response amplitudes to all other selected
% conditions. Response amplitudes are computed according the to
% event-related paramter 'ampType': see er_setParams, er_defaultParams.
%
% In addition to coding the degree of response, this also encodes the
% preferred condition in the following manner: if the first selected
% condition is preferred, the map ranges from 0-1; if the second, from 1-2;
% and so on. In general, the main value of the map is 
%   (preferred condition-1) + sel.
% 
% If 'gray' is provided as the ROI, will step through gray matter computing
% the map in a memory-efficient manner.
%
% This calls the multivoxel tool mv_exportSelectivity, so behaves exactly 
% as if you'd called a multivoxel UI and then exported selectivity, without
% de-selecting any conditions.
%
%
%
% ras, 05/01/06.
if notDefined('view'), view = getCurView;               end
if notDefined('roi'),  roi = view.selectedROI;          end
if notDefined('scans'), scans = er_getScanGroup(view);  end
if notDefined('dt'), dt = view.curDataType;              end
if notDefined('threshold'), threshold = 0.1;            end
if notDefined('conditions'), 
    trials = er_concatParfiles(view);
    conditions = trials.condNums(trials.condNums>0);
end

if ~isequal(roi, 'gray')
    % for an ROI: call mv_exportSelectivity
    mv = mv_init(view, roi, scans, dt);
    mv_exportSelectivity(mv, 1);
    return
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If we got here, we're doing a memory-efficient gray matter computation %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
roi = getGrayRoi(view);
nVoxels = size(roi.coords, 2);

hwait = mrvWaitbar(0, 'Computing Selectivity Map Across Gray Matter...');
for a = 1:1000:nVoxels
    b = min(nVoxels, a+999);
    subRoi = roi;
    subRoi.coords = roi.coords(:,a:b);
    subRoi.name = 'ROI1'; % will prevent lengthy caching of each sub-ROI

    mv = mv_init(view, subRoi, [], [], 1);

    sel(a:b) = mv_selectivity(mv, conditions, threshold);
    
    mrvWaitbar(b/nVoxels, hwait);
end
close(hwait);


% plug in the values to the map volume:
mapvol = zeros(dataSize(view));
ind = roiIndices(view, roi.coords);
mapvol(ind) = sel;

%%%%%map the category-independent selectivity into the co map
if ~isfield(mv,'wta'), mv=mv_reliability(mv,'plotFlag',0); end
covol = zeros(mapdims);
covol(ind) = mod(sel, 1);

%%%%%get voxel reliabilities, map to ph map
phvol = zeros(mapdims);
phvol(ind) = normalize(mv.wta.voxR, 0, 2*pi);

% covol = phvol; % rory temp hack 05/06: please delete

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
view=setParameterMap(view,map,mapName);
if saveFlag==1,
    saveParameterMap(view,[],1);
    saveCorAnal(view,1)
end
refreshScreen(view);

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

disp('Finished computing gray matter selecitivity map.')

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function roi = getGrayRoi(view);
% roi = getGrayRoi(view);
% find, load, or make a gray ROI for the view.

% try finding a loaded ROI
if ~isempty(view.ROIs)
    existingRois = {view.ROIs.name};
    N = cellfind(existingRois, 'gray');
    if ~isempty(N), roi = view.ROIs(N); return; end
end

% try loading a saved ROI
w = what(roiDir(view));
savedRois = w.mat';
if ~isempty(savedRois)
    N = cellfind(savedRois, 'gray.mat');
    if ~isempty(N)
        load(fullfile(roiDir(view), 'gray.mat'), 'ROI');
        roi = ROI; 
        return
    end
end

% got here: need to make it
try 
    view = makeGrayROI(view);
    roi = view.ROIs(end);
    saveROI(view, roi);    
catch
    disp('Couldn''t make a gray ROI. Segmentation installed?')
    roi = [];
end

return
