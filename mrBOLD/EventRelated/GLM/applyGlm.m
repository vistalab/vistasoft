function [vw, newScan] = applyGlm(vw, dt, scans, params, newDtName)
%Apply a General Linear Model (GLM) to view data
%
% [vw, newScan] = applyGlm([vw], [dataType], [scans], [params], [newDtName])
%
% The results are saved for further analyses in a GLM data type.
%
% INPUTS:
%   vw:     mrVista view structure. Defaults to current view if omitted.
%
%   dt:     name or number of the data type from which to take the scans.
%           Defaults to current data type.
%
%   scans:  scans from which to take data for GLM. Defaults
%             to scan group assigned to V's current scan. (If the scan
%             group is in a different data type, it will use that data
%             type, overriding the second argument.)
%
%   params: extended event-related analysis params. This has the same
%             fields as the standard event-related parameters (see
%             er_getParams, er_defaultParams), but may also have some extra
%             fields: 'lowPassFilter',  which if set to 1 will result in a
%             temporal smoothing of the data, cutting off frequencies above
%             ~20 cycles per scan.
%
%   'annotation': text to describe the GLM analysis. (E.g., 'Custom HRF,
%             All Scans', 'Scan 5 Omitted, whitened'.) When setting up the
%             new scan, the code will automatically add the original data
%             type name and scan numbers to this annotation.
%
%               [If omitted, the code pops up a GUI to get the params].
%
% newDtName: string to name the new data type (default GLM is good in
%             most cases)
%
% OUTPUTS:
%   newScan: scan # in which results are saved. Default appends
%               a new scan to the 'GLMs' data type.
%
% ras 06/06.
% ras, 02/06: fixed bug w/ 'newDtName' vs. 'newDtName'.
% ras, 11/06: new strategy. The results are always saved
% in the 'GLMs' data type, now.
% remus 5/07: (re?)added newDtName argument...very useful for some operations

%% Initialize variables and scan information
if notDefined('vw'), vw = getCurView; end
if notDefined('dt'), dt = viewGet(vw, 'curDataType');  end
if notDefined('scans'), [scans, dt] = er_getScanGroup(vw); end
if notDefined('params')
    params = applyGlmGUI(vw, scans, dt);
    if isempty(params), return; end
end
if notDefined('newDtName'), newDtName = 'GLMs';end
if (ischar(dt)) % Added support for string data type names
    tmp = existDataType(dt);
    if ~tmp, error(['Data type ''' dt ''' does not exist.']); end
    dt = tmp;
end

% mark the current slice, since the main loop will modify this
selectedSlice = viewGet(vw, 'curSlice');

% initialize the new scan,
[vw, newScan, tgtDt] = initScan(vw, newDtName, [], {dt scans(1)});

% set name (annotation) of the new scan
global dataTYPES
names = {dataTYPES.name};
newScanAnnotation = sprintf('%s: %s', names{dt}, num2str(scans));
if isfield(params, 'annotation') && ~isempty(params.annotation)
    newScanAnnotation = sprintf('%s (%s)', params.annotation, newScanAnnotation);
end
dataTYPES(tgtDt).scanParams(newScan).annotation = newScanAnnotation;
saveSession;

% store the event analysis params
er_setParams(vw, params, newScan, tgtDt);

% set the new 'scan' (slot in newDtName for the current GLM)
% to point at the source data as the scan group:
vw = er_groupScans(vw, scans, 1, dt);

% now point the view back at the source data:
% initScan selected the newly-created GLM scan, we want the orig. data
% for when we run applyGlmSlice in the main loop:
vw = viewSet(vw, 'curDataType', dt);
vw = viewSet(vw, 'curScan', scans(1));

% put some informative text in command window
fprintf('\n\n\t****** Applying GLM: %s ******\n', newScanAnnotation);
fprintf('\t(This will be saved in %s data type scan %i)\n', newDtName, newScan);

% report # of trials in each scan
stim = er_concatParfiles(vw, scans);
glm_trial_report(stim, 1);


%%   ***** Main Loop:  *****
% Slice loop eliminated: we now compute GLM on all slices at once. For
% backwards compatibility, we still save results as separate files for
% eachs slice.


tic;
nSlices = viewGet(vw, 'numSlices');
dims    = viewGet(vw, 'sliceDims');

% fprintf('Slice %i, %5.0f min %2.2f sec\n', sliceNum, floor(toc/60), mod(toc, 60));
sliceNum = 1:nSlices;
[model, vw] = applyGlmSlice(vw, sliceNum, scans, params);
saveGlmSlice(vw, model, newDtName, newScan, params);


% init variables:
% Collect some information, like betas and residuals, in separate volumes
% and save as maps, for fast contrast map calculations down the line.
% (the "sum" commands in lines 129-131 deal with the special case of
% deconvolution -- many betas per condition -- but doesn't affect other
% cases.)
betas  = cell(1,size(model.betas, 2));  % beta values for each condition
resStd = cell(1,size(model.betas, 2));  % residual standard deviation for each condition
resVar = cell(1,size(model.betas, 2));  % sum^2 of the residual variance explained
r2     = cell(1,size(model.betas, 2));  % proportion variance explained per voxel by the model

for c = 1:size(model.betas, 2)
    betas{c}  = reshape(sum(model.betas(:,c,:,:), 1), [dims nSlices]);
    resStd{c} = reshape(sum(model.stdevs(:,c,:,:), 1), [dims nSlices]);
    resVar{c} = reshape(sum(model.residual.^2) / model.dof, [dims nSlices]);
    r2{c}     = reshape(model.varExplained, [dims nSlices]);
end

% save the updated session params
saveSession;


%% *** Save extra parameter map info ***
vw = selectDataType(vw, newDtName);
nScans = viewGet(vw, 'nScans');

% save proportion variance explained
mapName = 'Proportion Variance Explained';
mapPath = fullfile(dataDir(vw), mapName);
if check4File(mapPath),
    load(mapPath, 'map');
else
    map = cell(1, nScans);
end
map{newScan} = r2{c};
save(mapPath, 'mapName', 'map');
fprintf('Saved prop. variance explained in %s\n', mapPath);

% save residual variance
mapName = 'Residual Variance';
mapPath = fullfile(dataDir(vw), mapName);
if check4File(mapPath),
    load(mapPath, 'map');
else
    map = cell(1, nScans);
end
map{newScan} = resVar{c};
save(mapPath, 'mapName', 'map');
fprintf('Saved sum-squared error saved in %s\n', mapPath);

% save betas and standard deviations
for c = 1:size(model.betas, 2)
    mapName = sprintf('betas_predictor%i', c);
    mapPath = fullfile(dataDir(vw), 'RawMaps', mapName);
    if check4File(mapPath)
        load(mapPath, 'map');
    else
        map = cell(1, nScans);
    end
    map{newScan} = betas{c};
    if c==1
        fprintf('Beta weights saved in %s\n', mapName(1:end-1));
        ensureDirExists(fileparts(mapPath));
    end
    save(mapPath, 'mapName', 'map');
    
    mapName = sprintf('stdDev_predictor%i', c);
    mapPath = fullfile(dataDir(vw), 'RawMaps', mapName);
    if check4File(mapPath)
        load(mapPath, 'map');
    else
        map = cell(1, nScans);
    end
    map{newScan} = resStd{c};
    save(mapPath, 'mapName', 'map');
    if c==1
        fprintf('Saved standard deviation in %s\n', mapPath);
    end
end

% select the originally-selected slice
vw = viewSet(vw, 'curSlice', selectedSlice);

%% Finished!  :)
fprintf('\n\n\t****** GLM Done. Time: %5.0f min %2.2f sec ******.\n\n', ...
    floor(toc/60), mod(toc,60));


return
% /---------------------------------------------------------------------/ %




% /---------------------------------------------------------------------/ %
function glm_trial_report(stim, fid)
% print out the # of events found for each condition
% for a set of scans.
fprintf(fid, '\n Trial Count: Condition\t');

for c = stim.condNums
    fprintf(fid, '%i\t', c);
end
fprintf(fid, '\n');

runs = unique(stim.run);
for s = 1:length(runs)
    fprintf(fid, '\t\tScan %i\t', s);
    for c = stim.condNums
        fprintf(fid, '%i\t', sum(stim.run==runs(s) & stim.cond==c));
    end
    fprintf(fid, '\n');
end

% report the sum of each trial type
fprintf(fid, [repmat('-', [1 80]) '\n\t\tTOTAL\t']);
for c = stim.condNums
    fprintf(fid, '%i\t', sum(stim.cond==c));
end
fprintf(fid, '\n');

return
% /---------------------------------------------------------------------/ %




%% /---------------------------------------------------------------------/
function params = applyGlmGUI(vw, scans, dt)
% Dialog for user to set applyGlm parameters.

mrGlobals;
params = [];

%%
scanList = {dataTYPES(dt).scanParams.annotation};
for i = 1:length(scanList)
    scanList{i} = sprintf('(%i) %s', i, scanList{i});
end

dlg(1).fieldName = 'scans';
dlg(1).style = 'listbox';
dlg(1).list = scanList;
dlg(1).string = 'Which scans to apply GLM?';
dlg(1).value = scans;

dlg(2).fieldName  = 'setParams';
dlg(2).style      = 'checkbox';
dlg(2).string     = 'Set Event-Related Parameters Before Running';
dlg(2).value      = 1;

dlg(3).fieldName = 'lowPassFilter';
dlg(3).style = 'checkbox';
dlg(3).string = 'Low-Pass Filter Time Series';
dlg(3).value = 0;

dlg(4).fieldName = 'annotation';
dlg(4).style = 'edit';
dlg(4).string = 'Description of this Analysis?';
dlg(4).value = '';


resp = generalDialog(dlg, 'applyGlm');

if isempty(resp), return; end

%%
for i = 1:length(resp.scans)
    tmp(i) = cellfind(dlg(1).list, resp.scans{i});
end

% We should check whether all the scans have the same parameters.  If we
% don't, this can cause a problem.
params = er_getParams(vw, scans(1), dt);

if resp.setParams==1
    p = er_editParams(params);
    if isempty(p), params = []; return; end
    params = mergeStructures(params, p);
end
params.lowPassFilter = resp.lowPassFilter;
params.annotation = resp.annotation;

return
