function view = concatenateScans(view, srcScans, convertToInt, outScan, tgtDt);
% view = concatenateScans(view, [srcScans, convertToInt, outScan, tgtDt='Preprocessed']);
%
% takes the selected input scans from the current datatype, detrends
% according to the selected option (0 for no detrend) and saves in the
% tgtDt data type as the selected outScan. If the Sorted data type
% doesn't exist, creates that.
%
% Also concatenates the parfiles assigned to each of the input Scans, creates
% a resulting concatenated parfile in the stim/parfiles directory (named
% 'sorted_scan[#].par') and assigns it to the resulting concatenated scan.
% Right now I only concatenate scans that have .par files assigned (that is,
% event-related scans or block related scans in which the block order is not
% ABAB type). So there needs to be a stim/parfiles directory in the session
% directory, and parfiles assigned to each of the inscans. If this becomes
% useful later w/o the parfiles, I'll set it as an option, but for now, it's
% useful to be mandatory.
%
%
% view: current mrLoadRet view.
%
% srcScans: array of scans to concatenate from current data type. If omitted
% or empty, puts up a graphical dialog to get them.
%
% convertToInt: if 1, will save the tSeries as uint8. This
% is very useful for larger tSeries, but causes accuracy
% to be lost (and maybe some other things.)
%
% detrend: detrend option. 0 == no detrend, 1 == ~highpass, 2 == quartic,
% -1 == linear. See detrendTSeries for more info.
%
%
% 01/04 ras.
% 10/04 incorporated into mrvista, added uint8 conversion,
% converts to % signal, made detrending mandatory.
% 01/09 remus - made output parfile include datatype in its name
mrGlobals;
global HOMEDIR dataTYPES;

if notDefined('view'),  view = getCurView;      end
if notDefined('tgtDt'), tgtDt = 'Preprocessed'; end
if notDefined('convertToInt'),    convertToInt = 0; end

% params
smoothFrames = 20;    % # of frames to use for highpass detrending
discardFromStart = 0; % # of frames to discard at the beginning of each scan (e.g. if blank bsl)
discardFromEnd = 0;   % # of frames to discard at the end of each scan (e.g. if blank bsl)
detrend = 1;          % detrend option

srcDt = view.curDataType;
viewType = view.viewType;

switch viewType
    case {'Inplane','Flat'},    nSlices = numSlices(view);
    case 'Gray',                nSlices = 1;
    otherwise,                  nSlices = 0;
end


if ~exist('srcScans','var') | isempty(srcScans)
    srcScans = er_selectScans(view);
end

% if necessary, initialize the tgtDt data type
tgt = [];
for i = 1:length(dataTYPES)
    if isequal(dataTYPES(i).name,tgtDt)
        tgt = i;
        break;
    end
end

if isempty(tgt)
    tgt = length(dataTYPES) + 1;
    dataTYPES(tgt).name = tgtDt;
    dataTYPES(tgt).scanParams = [];
    dataTYPES(tgt).blockedAnalysisParams = [];
    dataTYPES(tgt).eventAnalysisParams = [];
end

% also make a tgtDt directory/subdirs if necessary
sortedDir = fullfile(HOMEDIR,viewType,tgtDt);
if ~exist(sortedDir)
    cd(HOMEDIR);
    mkdir(fullfile(viewType,tgtDt));
    outScan = 1;
elseif ieNotDefined('outScan')
    outScan = length(dataTYPES(tgt).scanParams) + 1;
end

if ~exist(fullfile(viewType,tgtDt,'TSeries'),'dir')
    mkdir(fullfile(viewType,tgtDt,'TSeries'));
end

outDir = fullfile(viewDir(view),tgtDt,'TSeries',['Scan' num2str(outScan)]);
if ~exist(outDir,'dir')
    [a b] = fileparts(outDir);
    mkdir(a,b);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check whether parfiles are assigned to the input scans %
% (so we know whether to make a concatenated one later)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parCheck = 1;
for s = srcScans
    if ~isfield(dataTYPES(srcDt).scanParams(s),'parfile') | ...
            isempty(dataTYPES(srcDt).scanParams(s).parfile)
        parCheck = 0;
        break;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if parfiles assigned, concatenate them and save        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if parCheck==1
    fprintf('Concatenating parfiles ...\n');

    par.onset = [];
    par.cond = [];
    par.label = {};
    par.color = {};
    offset = 0;

    for s = srcScans
        parfile = dataTYPES(srcDt).scanParams(s).parfile;
        parpath = fullfile(parfilesDir(view), parfile);
        [onsets,conds,labels,colors] = readParFile(parpath);
        par.cond = [par.cond conds];
        par.label = [par.label labels];
        par.onset = [par.onset onsets+offset];
        par.color = [par.color colors];

        % # of time points so far in tSeries
        TR =  dataTYPES(srcDt).scanParams(s).framePeriod;
        nFrames = dataTYPES(srcDt).scanParams(s).nFrames;
        offset = offset + TR * nFrames;
    end

    outParName = sprintf('concatScan%i_%i.par',tgt,outScan);
    outParPath = fullfile(parfilesDir(view), outParName);
    writeParfile(par,outParPath);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize a hidden view for percentTSeries  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch view.viewType
    case 'Inplane', hView = initHiddenInplane;
    case 'Gray', hView = initHiddenGray;
    case 'Flat', hView = initHiddenFlat;
end
hView.curDataType = view.curDataType;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main loop: create output tSeries  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tStart = discardFromStart + 1;
h = mrvWaitbar(0,'concatenating selected scans...');
tic
for slice = 1:nSlices

    tSeries = [];

    % loop through each of the selected input srcScans
    for s = 1:length(srcScans)
        scan = srcScans(s);

        hView = percentTSeries(hView,scan,slice);
        srcTSeries = hView.tSeries;

        % append to output tSeries
        tEnd = size(srcTSeries,1) - discardFromEnd;
        tSeries = [tSeries; srcTSeries(tStart:tEnd,:)];
    end

    % save the sorted slice
    outputFileName = fullfile(outDir,['tSeries' num2str(slice) '.mat']);
    save(outputFileName,'tSeries');
    fprintf('Saved %s ...  (Time: %4.2f) \n',outputFileName,toc);

    mrvWaitbar(slice/numSlices(view),h);
end

close(h)

initScan(view, tgtDt, [], {srcDt srcScans(1)});

% % set dataTYPES params for this outScan
% annotation = sprintf('%s scans %s',dataTYPES(srcDt).name,num2str(srcScans));
% dataTYPES(tgt).scanParams(outScan).annotation = annotation;
% dataTYPES(tgt).scanParams(outScan).nFrames = ...
%     size(tSeries,1);
% dataTYPES(tgt).scanParams(outScan).framePeriod = ...
%     dataTYPES(srcDt).scanParams(srcScans(1)).framePeriod;
% dataTYPES(tgt).scanParams(outScan).slices = ...
%     dataTYPES(srcDt).scanParams(srcScans(1)).slices;
% dataTYPES(tgt).scanParams(outScan).cropSize = ...
%     dataTYPES(srcDt).scanParams(srcScans(1)).cropSize;
% dataTYPES(tgt).scanParams(outScan).parfile = outParName;
% 
% dataTYPES(tgt).blockedAnalysisParams(outScan).blockedAnalysis = 1;
% dataTYPES(tgt).blockedAnalysisParams(outScan).detrend = ~(detrend);
% dataTYPES(tgt).blockedAnalysisParams(outScan).inhomoCorrect = ...
%     ~(dataTYPES(srcDt).blockedAnalysisParams(srcScans(1)).inhomoCorrect);
% dataTYPES(tgt).blockedAnalysisParams(outScan).temporalNormalization = ...
%     ~(dataTYPES(srcDt).blockedAnalysisParams(srcScans(1)).temporalNormalization);
% dataTYPES(tgt).blockedAnalysisParams(outScan).nCycles = ...
%     dataTYPES(srcDt).blockedAnalysisParams(srcScans(1)).nCycles * length(srcScans);
% 
% dataTYPES(tgt).eventAnalysisParams(outScan).eventAnalysis = 1;
% dataTYPES(tgt).eventAnalysisParams(outScan).detrend = ~(detrend);
% dataTYPES(tgt).eventAnalysisParams(outScan).detrendFrames = smoothFrames;
% dataTYPES(tgt).eventAnalysisParams(outScan).temporalNormalization = 0;
% dataTYPES(tgt).eventAnalysisParams(outScan).inhomoCorrect = 0;

save mrSESSION dataTYPES -append;

fprintf('Done concatenating scans. Time = %4.2f secs.\n',toc);

return




%         srcTSeries = loadtSeries(view,srcScans(s),slice);
%
%         % detrend tSeries if selected
%         if detrend
%             srcTSeries = detrendTSeries(srcTSeries,detrend,smoothFrames);
%         end
%
%         % inhomogeneity correction
%     	dc = mean(srcTSeries);
% 		srcTSeries = srcTSeries./(ones(size(srcTSeries,1),1)*dc);
%
%         % subtract the mean, convert to % signal
%         srcTSeries = srcTSeries - ones(size(srcTSeries,1),1)*mean(srcTSeries);
%         srcTSeries = 100*srcTSeries;

%         % rescale, clip, convert to integer if selected
%         if convertToInt==1
%             minVal = max(-20,min(srcTSeries(:)));
%             maxVal = min(+20,max(srcTSeries(:)));
%             srcTSeries = rescale2(srcTSeries,[-20 20],[0 255]);
%             srcTSeries = uint16(srcTSeries);
%         end
