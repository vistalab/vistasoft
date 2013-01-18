function mrInitRetPreprocessScript(varargin)
% mrInitRet Preprocess Script
%
%  mrInitRetPreprocessScript(varargin)
%
%   Options:
%
%   -Slice-time correct* (INPLANES)  
%   -Between- and within-scan motion compensation* (INPLANES)
%   -Average t-series*,** 
%   -Calculate mean map
%   -Scan-to-scan reliability map**
%   -Coranal
%   -Xform to volume (requires a pre-existing alignment)
%   -compress raw p-files
%      *  creates new data data type
%      ** based on groups of scans with identical names
%   -emailAdress
%
% The code assumes you have already run mrInitRet, thereby setting up your
% directories and t-series, and creating a mrSession file. If you plan to
% average your data, the script works best if you give the same name to all
% scans that you want averaged. For example, if you do 8 retinotopy scans
% consisting of 4 bar scans, 2 wedge scans, and 2 ring scans, then you might
% name your scans:
% {'8 bars', '8 bars', '8 bars', '8 bars', 'Wedges', 'Wedges', 'Rings', 'Rings'}
% If you calculate averages, the script will generate an 'Averages'
% dataType with three scans, one for bars, one for wedges, and one for
% rings. Similarly, if you calculate scan-to-scan reliability, these
% calculations will operate on the groups of bars, wedges, and rings.
%
% Defauts:
%  sliceTimeCorrect = false;
%  motionComp       = false; 
%  computeAverages  = false;
%  computeCoranal   = false;  
%  computeXscan     = false;
%  computeMeanMap   = false; 
%  xformToVolume    = false;
%  compressRaw      = false;
%  emailAdress      = [];
%
%  input: {'all', true} or {'all', false} to set all fields at once
%
% Example 1: Use all defaults
% ---------------------------
%   mrInitRetPreprocessScript('all', true)
%
% Example 2: All steps except sliceTimeCorrect and motionComp
% ---------------------------
%  mrInitRetPreprocessScript('all', true, 'sliceTimeCorrect', false, 'motionComp', false) 
%
% Example 3: All steps except tranform to Volume
% ---------------------------
%  mrInitRetPreprocessScript('all', true, 'xformToVolume', false) 
%
% Example 4: All steps and email me when done
% ---------------------------
%  mrInitRetPreprocessScript('all', true, 'emailAddress', 'winawer@stanford.edu') 
%
% Example 5: All steps with non-default values for motion compensation and email me when done
% ---------------------------
%  mrInitRetPreprocessScript('all', true, 'baseScan', 6, 'baseFrame', 70, 'emailAddress', 'winawer@stanford.edu') 
%
% JW Jan, 2009
% 
 
mrGlobals;

% Variable check
if exist('varargin', 'var'),
    
    for ii = 1:2:length(varargin)
        switch lower(varargin{ii})
            case {'all'}
                pp.sliceTimeCorrect = varargin{ii+1};
                pp.motionComp       = varargin{ii+1};
                pp.computeAverages  = varargin{ii+1};
                pp.computeCoranal   = varargin{ii+1};
                pp.computeXscan     = varargin{ii+1};
                pp.computeMeanMap   = varargin{ii+1};
                pp.xformToVolume    = varargin{ii+1};
                pp.compressRaw      = varargin{ii+1};
            case {'slicetimecorrect', 'slicetime', 'slicetiming'}
                pp.sliceTimeCorrect = varargin{ii+1};
            case {'motioncomp', 'motion', 'motioncompensation', 'motion comp'}
                pp.motionComp = varargin{ii+1};
            case {'computeaverages', 'averages', 'average'}
                pp.computeAverages  = varargin{ii+1};
            case {'computexscancorr', 'xscan', 'xcorr', 'cross scan correlation' 'xscan correlation'}
                pp.computeXscan = varargin{ii+1};
            case {'computecoranal', 'coranal'}
                pp.computeCoranal   = varargin{ii+1};
            case {'computemeanmap', 'meanmap', 'mean', 'means'}
                pp.computeMeanMap   = varargin{ii+1};
            case {'xformtovolume', 'xform', 'xformtogray', 'xform2vol', 'xform2gray'}
                pp.xformToVolume    = varargin{ii+1};
            case {'compressraw', 'compress', 'zip', 'zipraw' 'compresspfiles' 'zippfiles'}
                pp.compressRaw      = varargin{ii+1};
            case {'basescan', 'motioncompbase', 'basemotioncomp'}
                baseScan            = varargin{ii+1};
            case {'baseframe', 'motioncompframe'}
                baseFrame           = varargin{ii+1};
            otherwise 
                warning('[%s]: Unknown input argumen %s', varargin{ii});
        end
    end
end

if ~exist('pp', 'var'), pp = []; end
if ~isfield(pp, 'sliceTimeCorrect'),  pp.sliceTimeCorrect = false;  end
if ~isfield(pp, 'motionComp'),        pp.motionComp       = false;  end
if ~isfield(pp, 'computeAverages'),   pp.computeAverages  = false;  end
if ~isfield(pp, 'computeCoranal'),    pp.computeCoranal   = false;  end
if ~isfield(pp, 'computeXscan'),      pp.computeXscan     = false;  end
if ~isfield(pp, 'computeMeanMap'),    pp.computeMeanMap   = false;  end
if ~isfield(pp, 'xformToVolume'),     pp.xformToVolume    = false;  end
if ~isfield(pp, 'compressRaw'),       pp.compressRaw      = false;  end

%% Get started
mrVista
s = selectedINPLANE;

%% Slice-time correct
%   This is annoying to automate since the slice order is usually not read
%   in automatically. For spiral sequences, we know that the order is
%   simple increasing function.
if pp.sliceTimeCorrect
    sliceOrder = sessionGet(mrSESSION,'sliceOrder',1);
    if notDefined('sliceOrder')
        warning('Cannot determine slice acquisition order. Assuming simple increasing order. This is true for Gary''s sprial sequences. Might not be true for other sequences.');
        nScans = viewGet(INPLANE{s}, 'numScans');
        nSlices = viewGet(INPLANE{s}, 'numSlices');
        for scan = 1:viewGet(INPLANE{s}, 'numScans')
            mrSESSION = sessionSet(mrSESSION,'sliceOrder',1:nSlices, scan);
        end
    end
    saveSession;
    INPLANE{s} = AdjustSliceTiming(INPLANE{s}, 0);
end
%% Motion compensation
if pp.motionComp
    if ~exist('baseScan', 'var'),  baseScan  = []; end
    if ~exist('baseFrame', 'var'), baseFrame = []; end
    
    INPLANE{s} = viewSet(INPLANE{s}, 'dataTYPEnumber', length(dataTYPES));
    INPLANE{s} = motionCompNestaresFull(INPLANE{s}, [], baseScan, baseFrame);

end

%% Averages
if pp.computeAverages
    INPLANE{s} = viewSet(INPLANE{s}, 'dataTYPEnumber', length(dataTYPES));
    confirm = false; % don't wait for user ok - just proceed
    INPLANE{s} = averageTSeriesAllScans(INPLANE{s}, [], confirm);

    % Cross-Scan Correlation Maps
    if pp.computeXscan
        dt = length(dataTYPES) - 1;
        INPLANE{s} = viewSet(INPLANE{s}, 'dataTYPEnumber', dt);
        confirm = false; % don't wait for user ok - just proceed
        try
            INPLANE{s} = computeCrossScanCorrelationMap(INPLANE{s},'group', confirm);
        catch ME
            warning(ME.message)
        end
    end
end
%% Correlation analysis
if pp.computeCoranal
    forceSave = true;
    for dt = 1:length(dataTYPES)
        INPLANE{s} = viewSet(INPLANE{s}, 'dataTYPEnumber', dt);
        INPLANE{s} = computeCorAnal(INPLANE{s},0, forceSave);
    end
end
%% Mean maps
if pp.computeMeanMap
    forceSave = true;
    for dt = 1:length(dataTYPES)
        INPLANE{s} = viewSet(INPLANE{s}, 'dataTYPEnumber', dt);
        INPLANE{s} = computeMeanMap(INPLANE{s},0, forceSave);
    end
end

%% Xform to volume
if pp.xformToVolume
    if ~exist('Gray/coords.mat', 'file')
        warning('[%s]: Skipping xform to gray because Gray coords not found', mfilename);
    else
        mrVista 3;
        si = selectedINPLANE;
        sv = selectedVOLUME;

        for ii = 1:length(dataTYPES)

            % Set the dataTYPE
            INPLANE{si} = viewSet(INPLANE{si}, 'curdataTYPE', ii);
            VOLUME{sv}  = viewSet(VOLUME{sv}, 'curdataTYPE', ii);
            % load the coranal
            INPLANE{si} = loadCorAnal(INPLANE{si});
            % xform the coranal
            VOLUME{sv}  = ip2volCorAnal(INPLANE{si},VOLUME{sv},0);
            % xform all other maps
            ip2volAllParMaps(INPLANE{si}, VOLUME{sv}, 'linear');
            % if we are in the last dataTYPE (presumably 'Averages'), then also
            % xform the t-series
            if strcmpi('averages', viewGet(INPLANE{1}, 'dtname')) 
                VOLUME{sv}=ip2volTSeries(INPLANE{si},VOLUME{sv},0,'linear');
            end
        end

        close(gcf);
    end
end

if pp.compressRaw
    compressRaw;
end
%% Close and clean
saveSession; close(gcf);  mrvCleanWorkspace;

if exist('emailAddress', 'var'), emailMe('Done with preprocessing!', emailAddress); end

% That's it
return


