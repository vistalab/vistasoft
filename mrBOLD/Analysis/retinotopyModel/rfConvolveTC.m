function [ctics,hd_resp,peak,specs]=rfConvolveTC(tics,FrameTime,wHrf,hrfParams)
% rfConvolveTC - convolve a given sequence with hdrf
%
% [ctics, hd_resp, peak, specs] = rfConvolveTC(tics, frametime, wHrf, hrfParams);
%    Convolve a given sequence with a haemodynamic
%    response function (wHrf) with params (hrfParams)
%
%    inputs : tics (sequence to be convolved)
%             FrameTime (TR, secs)
%             wHrf      ('boynton','twogammas')
%             hrfParams ([Torr Td],[peak1 fwhm1 peak2 fwhm2 dip])
%
%    'boynton' defaults: [1.68 3 2.05]
%    From Boynton et al, J Neurosci (1996) 16:4207-4221.
%    'twogammas' defaults:  [5.4 5.2 10.8 7.35 0.35]
%    From Glover, NeuroIm, (1999) 9:416-429, also used by
%    Worsley's fmristat: Worsley et al. NeuroIm (2002) 15:1-15.
%

% SOD: wrote it.
% JW, 4/1/2011: moved hrf subroutines intp separate functions
% (rmHrfBoynton, rmHrfTwogammas)
if ~exist('tics','var') || isempty(tics), error('need tics'); end
if ~exist('FrameTime','var') || isempty(FrameTime), error('need FrameTime'); end
if ~exist('wHrf','var') || isempty(wHrf), error('need wHRF'); end
if ~exist('hrfParams','var'), hrfParams = []; end

% if wHrf is char then make hrf otherwise we assume that wHrf
% provides the hd_resp (ie we only need to make it once)
if ischar(wHrf)
    % make hemodynamic response
    FIR_lengthsec = 50;
    FIR_frames    = ceil(FIR_lengthsec/FrameTime);
    FIR_time      = (0:FIR_frames)*FrameTime;
    switch lower(wHrf)
        case {'b','boynton','one gamma (boynton style)'}
            hd_resp    = rmHrfBoynton(FIR_time,hrfParams);
        case {'t','g','gamma','twogammas','two gammas (spm style)'}
            hd_resp    = rmHrfTwogammas(FIR_time,hrfParams);
        case {'impulse','i','none'}
            hd_resp    = 1;
        otherwise
            fprintf('[%s]:Unknown hrf function: %s',mfilename,wHrf);
            help(mfilename);
            return;
    end;
else
    hd_resp = wHrf;
end;

% normalize hdrf according to volume
hd_resp = hd_resp./(sum(hd_resp).*FrameTime); %  normalize

% convolve stimulus sequence with hdrf
ctics = filter(hd_resp(:),1,tics);
%ctics = ctics(1:size(tics,1),:);

% If requested find peak and give it as an output. This way we can
% normalize according to max response as well. We do this by remake
% hemodynamic response at a fine resolution and finding the
% max (HACK). TO DO: there must be a mathematical way of finding
% the exact peak response.
if nargout > 2,
    FrameTime     = 0.001;
    FIR_lengthsec = 15;
    FIR_frames    = ceil(FIR_lengthsec/FrameTime);
    FIR_time      = (0:FIR_frames)*FrameTime;
    switch lower(wHrf)
        case {'b','boynton','one gamma (boynton style)'}
            hd2    = rmHrfBoynton(FIR_time,hrfParams);
        case {'t','g','gamma','twogammas','two gammas (spm style)'}
            hd2    = rmHrfTwogammas(FIR_time,hrfParams);
        case {'impulse','i','none'}
            hd2    = 1;
        otherwise
            fprintf('[%s]:Unknown hrf function: %s',wHrf);
            help(mfilename);
            return;
    end;
    hd2 = hd2./(sum(hd2).*FrameTime);
    if nargout <4
      peak = max(hd2);
    else
      [peak ii] = max(hd2);
      peak = peak(1);
      specs.timeToPeak = (ii(1)-1).*FrameTime;
      specs.fwhm       = sum(hd2>=(peak./2)).*FrameTime;
    end;
end;

return;

%-------------------------------------------------------------

%-------------------------------------------------------------
