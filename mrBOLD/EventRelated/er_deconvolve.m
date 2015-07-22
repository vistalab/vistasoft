function [tgtDt, tgtScan] = er_deconvolve(view, srcScans, tgtScan, annotation)
% [tgtDt, tgtScan] = er_deconvolve(view, [scansToDeconvolve, newScanNum, annotation])
%
% 'Deconvolve' a set of scans, producing a new analysis in the Deconvolved
% data type. The time series in the new Deconvolved scan contains average
% time course estimates created by er_selxavg (which uses the Burock and
% Dale, Human Brain Mapping 2000 algorithm) plus variances for each non-null
% condition.
%
% Returns the Deconvolved data type number and scan number of the
% new data type.
%
% To do: produce a parfile for the deconvolved scan.
%
% view: mrVista view. <Defaults to selected inplane.>
%
% srcScans: scans to deconvolve in the current data type. <default: scan
% group>
%
% tgtScan: directory in which to save the target scans. [E.g.
% Inplane/Deconvolved/TSeries/Scan3/]. Default: append to the end
% of the Deconvolved data type, prompting user to confirm.
%
% 06/20/03 ras
% 08/04 ras: now saves to 'Deconvolved' data type rather
% than 'Averages'.
% 02/20/06 ras: updated to use newer code for dealing w/ data types.
% 02/22/06 ras: renamed from 'er_runSelxavg' to 'er_deconvolve'.
% Also fixed major bug in which the TER parameter was set to 1, which
% caused an error if you had data that didn't have a TR of 1.
if notDefined('view'), view = getSelectedInplane; end
if notDefined('tgtScan'), prompt = 1; else, prompt = 0; end

global HOMEDIR dataTYPES

opts = {};

%%%%% ensure the Deconvolved directory exists
deconvolvedDir = fullfile(HOMEDIR,'Inplane','Deconvolved','TSeries');
if ~exist(deconvolvedDir, 'dir'), mkdir(deconvolvedDir); end

%%%%% build up list of tSeries directories for later use %%%%%
a = filterdir('Scan', tSeriesDir(view));
b = filterdir('Scan', deconvolvedDir);

%%%%% get data types #s for current and deconvolved dts
srcDt = viewGet(view,'curDataType');
srcDtName = dataTYPES(srcDt).name;
tgtDt = existDataType('Deconvolved');
if tgtDt==0 % haven't created Deconvolved dt yet
    tgtDt = length(dataTYPES)+1;
    tgtScan = 1;
else
    tgtScan = length(dataTYPES(tgtDt).scanParams) + 1;
end

tgtPath = fullfile(deconvolvedDir, ['Scan' num2str(tgtScan)]);

if notDefined('srcScans')
    [srcScans srcDt] = er_getScanGroup(view);
    view = selectDataType(view, srcDt);
end

if prompt==1
    %%%%% confirm choice of output TSeries location %%%%%
    button = questdlg({'I will save the resulting tSeries in ',...
        '',tgtPath,'','Is This Ok?'});
    if isequal(button,'No')
        msg = 'Ok, enter number of Deconvolved Scan you''d like to use: ';
        tgtScan = inputdlg({msg}, mfilename, 1, {num2str(tgtScan)});
        tgtScan = str2num(tgtScan{1});
        tgtPath = fullfile(deconvolvedDir, ['Scan' num2str(tgtScan)]);
    elseif isequal(button,'Cancel')
        % currently not offering ability to redirect output
        return
    end
end


%%%%% build up opts cell, which will provide the arguments for selxavg %%%%%
stim = er_concatParfiles(view, srcScans);
params = er_getParams(view, srcScans(1));

TR = dataTYPES(1).scanParams(srcScans(1)).framePeriod;
prestim = min(min(params.timeWindow), 0);
nh = length(unique(round(params.timeWindow / TR))); % frames in deconvolved tcs
nConds = sum(stim.condNums>0); % # non-null conditions

% add options first (using standard options for now)
opts = {...
    '-highpass', '60', '-saveover', '-baseline', ...
    '-timewindow', num2str(nh*TR), ...
    '-prestim', num2str(prestim), ...
    '-TR', num2str(TR), '-TER', num2str(TR), ...
    '-nskip' ,'0', '-fwhm', '0',...
    };

% error covariance matrix
% (first for all runs, then for each run)
opts = [opts {'-ecovmtx'}];
opts = [opts {tgtPath}];
opts = [opts {'-svecovmtx'}];

% input paths and parfiles
srcScans;
for i = 1:length(srcScans)
    inPath = fullfile(tSeriesDir(view), sprintf('Scan%i', srcScans(1)));
    opts = [opts {'-i' inPath}];
    opts = [opts {'-p' stim.parfiles{i}}];
end

% output path
opts = [opts {'-o'}];
opts = [opts {tgtPath}];

opts{:};

%%%%% call er_selxavg to do the selective averaging %%%%%
cmd = ['er_selxavg(''' opts{1} ''''];
for i = 2:length(opts)
    cmd = [cmd ',''' opts{i} ''''];
end
cmd = [cmd ');'];
eval(cmd);


%%%%% make a new parfile for the deconvolved scan %%%%%
parPath = er_deconvolvedParfile(view, stim, params);
[ignore newParfile] = fileparts(parPath);

%%%%% fix dataTYPES to have info on the new scan %%%%%
initScan(view, 'Deconvolved', tgtScan, {srcDtName srcScans(1)});
if notDefined('annotation')
    % heuristic to find the common description in the parfiles
    for i = 1:length(stim.parfiles)
        [p f{i}] = fileparts(stim.parfiles{i});
    end
    annotation = f{1}(ismember(f{1}, intersect(f{1}, f{2})));
    annotation(annotation=='_') = ' ';
end
dataTYPES(tgtDt).scanParams(tgtScan).annotation = annotation;
dataTYPES(tgtDt).scanParams(tgtScan).nFrames = 2 * nh * nConds;
dataTYPES(tgtDt).scanParams(tgtScan).framePeriod = TR;
dataTYPES(tgtDt).scanParams(tgtScan).parfile = newParfile;
dataTYPES(tgtDt).scanParams(tgtScan).fsd = tgtPath;
dataTYPES(tgtDt).blockedAnalysisParams(tgtScan).nCycles = nConds;
save(fullfile(HOMEDIR,'mrSESSION.mat'), 'dataTYPES', '-append');

mrGlobals;
INPLANE = resetDataTypes(INPLANE);
VOLUME = resetDataTypes(VOLUME);
FLAT = resetDataTypes(FLAT);

fprintf('\n***** Finished Deconvolving. Updated dataTYPES. *****\n\n');

return
