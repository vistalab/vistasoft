function val = viewGetTimeSeries(vw,param,varargin)
% Get data from various view structures
%
% This function is wrapped by viewGet. It should not be called by anything
% else other than viewGet.
%
% This function retrieves information from the view that relates to a
% specific component of the application.
%
% We assume that input comes to us already fixed and does not need to be
% formatted again.

if notDefined('vw'), vw = getCurView; end
if notDefined('param'), error('No parameter defined'); end

mrGlobals;
val = [];


switch param
    
    case 'tseriesdir'
        % Return tSeries directory for a view; make it if it does not
        % exist.
        %   makeIt = 0; tDir = viewGet(vw,'tSeriesDir',makeIt);
        %   makeIt = 1; tDir = viewGet(vw,'tSeriesDir',makeIt);
        %   tDir = viewGet(vw,'tSeriesDir')
        if ~isempty(varargin), makeIt = varargin{1};
        else makeIt = 0;
        end
        val = tSeriesDir(vw,makeIt);
    case 'datasize'
        % Return the size of the data arrays, i.e., size of co for
        % a single scan.
        %  dataSize = viewGet(vw, 'Data Size');
        %  scan = 1; dataSize = viewGet(vw, 'Data Size', scan);
        val = double(dataSize(vw));
    case 'dim'
        % Return the dimension of data in current slice or specificed slice
        %   dim = viewGet(vw, 'Slice Dimension')
        %   scan = 1; dim = viewGet(vw, 'Slice Dimension', scan)
        switch vw.viewType
            case 'Inplane'
                val = mrSESSION.functionals.cropSize; %TODO: Change this once we get functional data at the veiw level
            case {'Volume','Gray'}
                val = [1,size(vw.coords,2)];
            case 'Flat'
                val = [vw.ui.imSize];
        end
    case 'functionalslicedim'
        % Return the dimension of functional data in current slice or
        % specificed slice
        %   dim = viewGet(vw, 'Slice Dimension')
        %   scan = 1; dim = viewGet(vw, 'Slice Dimension', scan)
        switch vw.viewType
            case 'Inplane'
                scan = 1; %We want the first scan of the first dataTYPE
                val = dtGet(dataTYPES(1),'Func Size', scan);
            case {'Volume','Gray'}
                val = [1,size(vw.coords,2)];
            case 'Flat'
                val = [vw.ui.imSize];
        end
        
    case 'tseries'
        % Return the time series of all data currently loaded into the view
        % struct.
        %   tseries = viewGet(vw, 'time series');
        val = vw.tSeries;
    case 'tseriesslice'
        % Return the time series for the currently selected slice if it is
        % loaded into the view struct (return blank otherwise).
        %   tseries = viewGet(vw, 'Time Series Slice');
        val = vw.tSeriesSlice;
    case 'tseriesscan'
        % Return the time series for the current scan (if it is loaded into
        % the view struct; return blank if it is not loaded).
        %   tseriesScan = viewGet(vw, 'time series scan');
        val = vw.tSeriesScan ;
        %TODO: Remove the below's use of multiple parameters. Do this for
        %all of the viewGet files
    case {'tr' 'frameperiod' 'framerate'}
        % Return the scan TR in seconds
        %   tr = viewGet(vw,'tr')
        %   scan = 1; tr = viewGet(vw,'tr',scan)
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt   = viewGet(vw, 'dtStruct');
        val  = [dt.scanParams(scan).framePeriod];
        
    case 'nframes'
        % Return the number of time frames in the current or specified
        % scan.
        %   nframes = viewGet(vw,'nFrames');
        %   scan = 1; nframes = viewGet(vw,'nFrames',scan);
        if isempty(varargin) || isempty(varargin{1})
            scan = viewGet(vw, 'CurScan');
        else
            scan = varargin{1};
        end
        dt  = viewGet(vw, 'dtStruct');
        val = [dt.scanParams(scan).nFrames];              
        
    otherwise
        error('Unknown viewGet parameter');
        
end

return
