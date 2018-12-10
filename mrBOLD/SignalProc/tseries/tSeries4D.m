function tMat = tSeries4D(vw, scan, verbose, varargin)
% tMat = tSeries4D(vw,[scan],[verbose]);
%
% Produce a 4D matrix of size rows x cols x slices x time
% for the current view/scan.
%
% verbose: flag to put up a mrvWaitbar. Defaults to 0, off.
%
% varargin: see percentTSeries help for explanation of options
%       UseDefaults - set to 1 to use data processing defaults
%       Detrend
%       InhomoCorrection
%       TemporalNormalization
%       NoMeanRemove
%
% 08/10 rfb - added varargin.
% 12/04 ras.
% 03/05 ras: trying to save memory by using uint16's.

if ieNotDefined('scan'),    scan = viewGet(vw, 'Current Scan'); end
if ieNotDefined('verbose'), verbose = 0; end

% Defaults to raw to preserve prior functionality of function
detrend                 = 0;
inhomoCorrection        = 0;
temporalNormalization   = 0;
noMeanRemove            = 1;

for i = 1:2:length(varargin)
    switch (lower(varargin{i}))
        case {'detrend'}
            detrend = varargin{i + 1};
        case {'inhomocorrection'}
            inhomoCorrection = varargin{i + 1};
        case {'temporalnormalization'}
            temporalNormalization = varargin{i + 1};
        case {'nomeanremove'}
            noMeanRemove = varargin{i + 1};
        case {'usedefaults'} % anything but 1 is a no op
            if (varargin{i + 1} == 1)
                detrend = detrendFlag(vw, scan);
                inhomoCorrection = inhomoCorrectionFlag(vw, scan);
                temporalNormalization = 0;
                noMeanRemove = 0;
            end
        otherwise
            fprintf(1, 'Unrecognized options: ''%s''', varargin{i});
    end
end

switch viewGet(vw, 'viewType')
    case {'Inplane'},
        dims    = dataSize(vw, scan);
        nFrames = numFrames(vw, scan);
                           
        if verbose, fprintf('Loading tSeries...\n'); end
        
        slices = 1:viewGet(vw, 'numSlices');
        vw = percentTSeries(vw, scan, slices, detrend, ...
            inhomoCorrection, temporalNormalization, noMeanRemove);
        tSeries = viewGet(vw, 'tSeries');
        tSeries = permute(tSeries, [2 3 1]); % put time in last dimension
        tMat = reshape(tSeries, [dims nFrames]); % rows and cols separate
                
    case {'Flat'},
        tMat = flatLevelTSeries(vw,scan);
    otherwise,
        error('%s vw not supported yet.',viewGet(vw, 'viewType'));
end

return
