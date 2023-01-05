function vw = computeSnrMap(vw,scanList, forceSave, varargin)
%
% vw = computeSnrMap(vw,[scanList], [forceSave])
%
% Cycles through tSeries, computing the temporal SNR map of the functional
% images = log10(mean / std).  Puts them together into a parameter map and
% calls setParameterMap to set vw.map = snrMap. We calculate the log
% because SNR is a highly skewed distribtion ([0 inf]). Taking the log
% makes the distribution approximately normal.
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
% varargin:  ('parameter', value) pairs. Can include:
%               ('logscale', 0 or 1)
%               ('temporalDetrend', 0 or 1), default calculation is
%               mean/std. If we use use temporal detrend method, we use
%               kendrick's function 'computetemporalsnr' which does a more
%               complicated calculation.  Requires Kendrick's matlab
%               utilities. See computetemporalsnr.m
%
% If you change this function make parallel changes in:
%    computeCorAnal, computeResStdMap, computeMeanMap, computeSnrMap
%
% JW   May 2012: adapted from computeStdMap

nScans = viewGet(vw,'numScans');

if notDefined('forceSave'), forceSave = 0; end

if exist('varargin', 'var')
    for ii = 1:2:length(varargin)
       switch lower(varargin{ii})
           case 'logscale'
               logscale = varargin{ii+1};
           case {'temporaldetrend' 'method'}
               temporalDetrend = varargin{ii+1};
           otherwise
               error('unknown input argument %s', varargin{ii});
       end
    end
end

if notDefined('logscale'), logscale = 1; end
if notDefined('temporalDetrend'), temporalDetrend = 0; end
    
if strcmp(vw.mapName,'stdMap')
    % If exists, initialize to existing map
    map=vw.map;
else
    % Otherwise, initialize to empty cell array
    map = cell(1,nScans);
end

% (Re-)set scanList
if ~exist('scanList','var'), scanList = selectScans(vw);
elseif scanList == 0,        scanList = 1:nScans;     end

if isempty(scanList), error('Analysis aborted'); end

waitHandle = mrvWaitbar(0,'Computing snr images from the tSeries.  Please wait...');

ncScans = length(scanList);

% Clip the map at 99th percentile of the distribution as outliers might
% otherwise result in an inappropriate color map (including values that are
% too high).
mx = zeros(1,ncScans);

for iScan = 1:ncScans
    scan = scanList(iScan);
    slices = sliceList(vw,iScan);
    dims    = viewGet(vw, 'sliceDims', iScan);
    datasz  = viewGet(vw, 'dataSize',  iScan);
    
    map{scan} = NaN*ones(datasz);
    for slice = slices
        tSeries = loadtSeries(vw,scan,slice);
        
        if temporalDetrend
            % A different calculation of SNR, used by Kendrick. This
            % calculation requires kendrick's matlab utilities. The main
            % differences are that (1) it regresses out a line, and (2)
            % computes differences over sequential points instead of all
            % points at once in order to be relatively insensitive to
            % actual activations (which tend to be slow), if they exist.
            tmp = zeros(size(tSeries,2), 1, 1, size(tSeries,1));
            tmp(:,1,1,:) = tSeries';
            tmp = computetemporalsnr(tmp);
            tmp = 1./tmp; % because kendrick's snr is really nsr (noise/signal)
            
        else            
            tmp = mean(tSeries) ./ std(tSeries);
            tmp(tmp<0) = 0;
        end
        if logscale, tmp = log10(tmp); end
        tmp(~isfinite(tmp)) = 0; % avoid inf in case std is 0
        map{scan}(:,:,slice) = reshape(tmp,dims);        
    end
    mx(iScan) = prctile(map{scan}(:), 99);
    mrvWaitbar(scan/ncScans)
end
close(waitHandle);

% Set parameter map
if      logscale && ~temporalDetrend, 
    name = 'snrMap';
    units = 'Log10(mean/std)';
elseif  ~logscale && ~temporalDetrend  
    name = 'snrMap';
    units = 'mean/std';
elseif  logscale && ~temporalDetrend  
    name = 'temporal snrMap';
    units = '(log10)';
elseif  logscale && ~temporalDetrend  
    name = 'temporal snrMap';
    units = '';
end
    
    
vw = setParameterMap(vw,map,name, units);

% set the limits of the color bar
disp(mx)
vw = viewSet(vw, 'map clip', [0 max(mx)]);

% Save file
if forceSave >= 0, saveParameterMap(vw, [], forceSave); end
