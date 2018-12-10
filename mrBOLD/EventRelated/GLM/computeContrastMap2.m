function vw = computeContrastMap2(vw, active, control, contrastName, varargin);
%
%  view = computeContrastMap2(view, active, control, contrastName, [options]);
%
% Compute a statistical contrast map on data for a view, applying
% a GLM if necessary. Updated version, using the rewritten GLM code.
%
% The map is computed off data from the scan group assigned to
% the view's current scan. (You can specify a different scan
% group as an optional argument). The map is added to the 
% view's map field, and saved in the view's data dir under
% the specified contrast name. 
%
% By default, the map represents the -log10(p) value of a statistical
% T test between the active and control conditions. So, a value of
% 2 indicates that the active conditions are greater than the
% control with a significance of 10^-2, a value of 3 is 10^-3, and
% a value of -2 indicates that control > active with a likelihood of 
% 10^-2. Other tests (F test rather than T test) and mapUnits are possible
% using the options specified below.
%
%
%
%
% Options include: 
%
%   [add options for varying slice, statistical test, mapUnits]
%
%
% ras 06/06
% ras 02/07: had some 'quickCompute' code in here, but after testing out
% load times, it looks like loading part of the GLM information doesn't
% save time over loading everything. So, kept it simple and removed the
% quickCompute code. Also: saves the mapUnits in a separate variable, will
% update param map code to show mapUnits if they're specified (and maybe if
% the user sets a flag).
% dar 02/07: made the bicolormap assignment conditional on the presence of
% a ui field in view (was crashing on hiddeninplanes).
if nargin<1, help(mfilename); return; end

%%%%% default params
test = 't';

% allow for a user input if the active and control
% conditions aren't specified
if ~exist('active','var') | isempty(active) |  ...
	~exist('control','var') | isempty(control) 
   prompt={'Active (+) Conditions:' ...
           'Control (-) Conditions:' ...
           'Contrast Name (if blank, will name based on condition names)'};
   def={'1' '0' ''};
   dlgTitle='Compute Contrast Map 2';
   
   answer=inputdlg(prompt, dlgTitle, 1, def);
   
   active = str2num(answer{1});
   control = str2num(answer{2});
   contrastName = answer{3};
end
scan = viewGet(vw,'curScan');
opts = {};
verbose = prefsVerboseCheck; 
if verbose,		tic;	end   % time the map computation
tcWeights = [];
    
%%%%% parse the options
for i = 1:length(varargin)
    switch(lower(varargin{i}))
        case 'f',           test = 'f';
        case 't',           test = 't';
		case 'fdr',		opts = [opts {'mapUnits' 'fdr'}];
        case {'w' 'weights'}  % contrast weights
            opts = [ opts { 'weights' varargin{i+1} } ];
        case {'tcweights'}, tcWeights = varargin{i+1};
        case 'mapunits', opts = [opts {'mapUnits'}];, opts=[opts {varargin{i+1}}];
    end
end

%% auto-add tcWeights option for 'selective averaging' GLMs:
params = er_getParams(vw);
if params.glmHRF==0  % flag for deconvolution
	% what this means is, if the GLM didn't assume an HRF, but instead
	% generated several beta values for each condition (1 per time point in a
	% peri-stimulus time window), we want to specify those betas (=frames in time
	% course) to use for the contrast. This should be the same points selected
	% as the 'peakPeriod' parameter. Formally, tcWeights should support 
	% differential weighting across time ponts, but right now the glm_contrast code 
	% treats it as a list of frames:
	f1 = fix( min(params.timeWindow) / params.framePeriod );  
	f2 = fix( max(params.timeWindow) / params.framePeriod );
	pk1 = fix( min(params.peakPeriod) / params.framePeriod );  
	pk2 = fix( max(params.peakPeriod) / params.framePeriod );
	tcWeights = find(ismember(f1:f2, pk1:pk2)); 
	opts = [opts {'tcWeights' tcWeights}];
end


%% default contrast name
if ~exist('contrastName','var') | isempty(contrastName)
	trials = er_concatParfiles(vw);
    activeNames = ''; controlNames = '';
    for i = 1:length(active)
        j = find(trials.condNums==active(i));
        activeNames = [activeNames trials.condNames{j}];
    end
    for i = 1:length(control)
        j = find(trials.condNums==control(i));
        controlNames = [controlNames trials.condNames{j}];
    end
    contrastName = sprintf('%sV%s', activeNames, controlNames)
end

%% check if a GLM has been run; if not, run one:
checkPath = fullfile(dataDir(vw),sprintf('Scan%i',scan),'glmSlice1.mat');
if ~exist(checkPath,'file')
    % no GLM file found -- ask user if they want to run one
    mrGlobals;
    [scans dt] = er_getScanGroup(vw,scan);
    names = {dataTYPES.name};
    q = 'A GLM wasn''t found for this slice and scan. ';
    q = [q 'Do you want to run one now? '];
    q = [q sprintf('%s scans %s',names{dt},num2str(scans))];
    resp = questdlg(q,'Compute Contrast Map');
    if isequal(resp,'Yes')
        % compute one
        vw = selectDataType(vw,dt);
        vw = setCurScan(vw,scans(1));
        [newDt newScan] = applyGlm(vw, scans);
        vw  = selectDataType(vw, newDt);
        vw = setCurScan(vw, newScan);
    else
        disp('Aborting computeContrastMap2')
        return
    end
end

% initialize map cell (of size nScans): 
% If another map with the same name has already been
% computed, load this: we'll just plug in the data for
% the current scan:
mapPath = fullfile(dataDir(vw),[contrastName '.mat']);
if exist(mapPath, 'file')
    load(mapPath, 'map', 'mapName');
else
    mapName = contrastName;
    map = cell(1, viewGet(vw, 'numScans'));
end

% initalize volume for the map
mapVol = NaN*ones(dataSize(vw, scan));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main loop: load data from each slice and compute map  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if verbose, hwait = mrvWaitbar(0,'Computing Contrast Map'); end

nSlices = viewGet(vw, 'numSlices');
for slice = 1:nSlices
	model  = loadGlmSlice(vw, slice, scan);		

	mapVol(:,:,slice) = glm_contrast(model, active, control, ...
									   'size', viewGet(vw, 'sliceDims'), opts);

	if verbose, mrvWaitbar(slice/nSlices, hwait);  end
end

if verbose, close(hwait);	end
    

%% set new map in view
mapUnits = '-log(p)';  % default
if cellfind(opts, 'mapUnits')
    mapUnits = opts{ cellfind(opts, 'mapUnits') + 1 };
end
if isequal(mapUnits, 'log10p'), mapUnits = '-log(p)'; end   % clarify
map{scan} = mapVol;
vw.mapUnits = mapUnits;
vw = setParameterMap(vw, map, mapName);
if checkfields(vw, 'ui', 'mapMode')
	vw = bicolorCmap(vw);  % take a chance that people will like this
end

% set the variance explained as the coherence
varExpPath = fullfile(dataDir(vw), 'Proportion Variance Explained');
if check4File(varExpPath)
	tmp = load(varExpPath, 'map');
	co = tmp.map;
else
	% this will wipe out any existing co data when the map is loaded:
	% but since we're in the GLMs data type, that should be ok.
	co = cell(1, numScans(vw));
end

%% save results
if exist(mapPath,'file')
    save(mapPath, 'map', 'mapName', 'mapUnits', 'co', '-append');
else
    save(mapPath, 'map', 'mapName', 'co', 'mapUnits');
end
fprintf('Saved Contrast Map in %s.\n', mapPath);

%% refresh screen according to whether we're using mrVista 1 or 2:
global GUI
if ~isempty(GUI)
    sessionGUI_selectDataType;  % mrVista 2
else
    vw = refreshScreen(vw, 1);        % mrVista 1
end

if verbose
	fprintf('Time to compute map: %i min, %3.1f sec.\n\n', ...
		floor(toc/60), mod(toc, 60));
end

return

