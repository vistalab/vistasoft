function vw = computeCorAnal(vw,scanList,forceSave)
% Compute coherence analysis, amp, phase and coherence
%
%  vw = computeCorAnal(vw,[scanList],[forceSave],[framesToUse])
%
% Loops throughs scans and slices, loads corresponding tSeries, computes
% correlation analysis from tSeries, and saves the resulting co, amp, and
% ph to the corAnal.mat file.
%
% scanList:
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% forceSave: 1 = true (overwrite without dialog)
%            0 = false (query before overwriting)
%           -1 = do not save
%
% If you change this function make parallel changes in:
%    computeResStdMap, computeStdMap, computeMeanMap
%
% djh, 2/21/2001, updated to mrLoadRet-3.0
if notDefined('forceSave'),   forceSave = 0;   end

nScans = viewGet(vw,'numScans');

% load the corAnal file if it's not already loaded
corAnalFile = fullfile(dataDir(vw), 'corAnal.mat');
if exist(corAnalFile,'file'), vw = loadCorAnal(vw); end

% If corAnal file doesn't exist, initialize to empty cell array
if isempty(vw.co)
    co  = cell(1, nScans);
    amp = cell(1, nScans);
    ph  = cell(1, nScans);
else
    co  = viewGet(vw, 'co');
    amp = viewGet(vw,'amp');
    ph  = viewGet(vw,'ph');
end

% (Re-)set scanList
if ~exist('scanList','var'),  scanList = er_selectScans(vw);
elseif scanList == 0,         scanList = 1:nScans;
end

if isempty(scanList),  error('Analysis aborted'); end

disp('Computing corAnal...');
waitHandle = mrvWaitbar(0,'Computing corAnal matrices from the tSeries.  Please wait...');
for scanIndex=1:length(scanList)
    
    scanNum = scanList(scanIndex);
    disp(['Processing scan ', int2str(scanNum),'...']);
    dims    = viewGet(vw, 'sliceDims', scanNum);
    nCycles = viewGet(vw, 'numcycles', scanNum);
    datasz  = viewGet(vw, 'dataSize',  scanNum);
    
    co{scanNum}  = NaN*ones(datasz);
    amp{scanNum} = NaN*ones(datasz);
    ph{scanNum}  = NaN*ones(datasz);

    sliceNum = sliceList(vw,scanNum);
    framesToUse = viewGet(vw, 'frames to use', scanNum);
    [coSeries,ampSeries,phSeries] = ...
        computeCorAnalSeries(vw, scanNum, sliceNum, nCycles, framesToUse);
    switch vw.viewType
        case {'Inplane' 'Flat'}
            co{scanNum}  = reshape(coSeries,  dataSize(vw));
            amp{scanNum} = reshape(ampSeries, dataSize(vw));
            ph{scanNum}  = reshape(phSeries,  dataSize(vw));
        case {'Gray' 'Volume'}
            co{scanNum}  = coSeries;
            amp{scanNum} = ampSeries;
            ph{scanNum}  = phSeries;
        otherwise
            error('Unkown vw type.')
    end
    
    mrvWaitbar(scanIndex/length(scanList), waitHandle);
end
close(waitHandle);

% Set coranal fields in the vw
vw.co  = co;
vw.amp = amp;
vw.ph  = ph;

% Save coherence analysis
if forceSave >= 0, saveCorAnal(vw, [], forceSave); end

return;

