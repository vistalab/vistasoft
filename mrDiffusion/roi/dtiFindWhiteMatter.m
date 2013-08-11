function [wmProb,faErr,mdErr,eigVal] = dtiFindWhiteMatter(eigVal,b0,xformToAcpc)
%
%  wmProb = dtiFindWhiteMatter(dt6_or_eigVals,b0,[xformToAcpc])
%
% Example usage:
% b0=niftiRead('dti06/bin/b0.nii.gz');
% b0 = double(b0.data);
% dt6=niftiRead('dti06/bin/tensors.nii.gz');
% dt6 = double(squeeze(dt6.data(:,:,:,1,[1 3 6 2 4 5])));
% wmProb = dtiFindWhiteMatter(dt6,b0);
% dtiWriteNiftiWrapper(uint8(round(wmProb*255)),xformToAcpc,'dti06/bin/wmProb.nii.gz',1./255) 
%
% HISTORY:
% 2007.07.24 RFD: wrote it.

% This var isn't used any more, but many callers pass it in.
if(~exist('xformToAcpc','var')), xformToAcpc = []; end

finalThresh = 0.5;
histClipB0 = false;

targetMd = [0.6 1.0]; % in micrometers^2/msec
targetFa = [0.4 1.0];

if(~isempty(b0))
   if(~isa(b0,'double'))
      b0 = double(b0);
   end
   % Make sure the b0 is histogram clipped
   if(max(b0(:))>1)
      b0 = mrAnatHistogramClip(b0,0.4,0.99);
   end
end
%templateFile = which('whiteMatter.nii.gz');

% Ensure diffusivity units are in micrometers^2/msec
[curUnitStr,scale] = dtiGuessDiffusivityUnits(eigVal);
eigVal = eigVal.*scale;
if(size(eigVal,4)==6)
    [eigVec,eigVal] = dtiEig(eigVal);
    clear eigVec;
end

%% Compute FA Error term
[fa,md] = dtiComputeFA(eigVal);
faErr = zeros(size(fa));
faErr(fa<targetFa(1)) = (targetFa(1)-fa(fa<targetFa(1)))./targetFa(1);
faErr(fa>targetFa(2)) = (fa(fa>targetFa(2))-targetFa(2))./targetFa(2);
faErr(faErr>1) = 1;
faErr(isnan(faErr)) = 1;

% things with bogus fa>=1 values are always bad
%faErr(fa>=1) = 1;

%% Compute MD Error term
% TODO: ensure md is in micrometers^2/msec!
mdErr = zeros(size(md));
mdErr(md<targetMd(1)) = (targetMd(1)-md(md<targetMd(1)))./targetMd(1);
mdErr(md>targetMd(2)) = (md(md>targetMd(2))-targetMd(2))./targetMd(2);
mdErr(mdErr>1) = 1;
mdErr(isnan(mdErr)) = 1;

%% Compute location prior from a template
%locPriorNi = niftiRead(templateFile);
sz = size(faErr);
%xf = locPriorNi.qto_ijk*xform;
%[sampZ,sampY] = meshgrid([1:sz(2)],[1:sz(1)]);
%sampY = sampY(:); sampZ = sampZ(:); 
%coords = mrAnatXformCoords(xf,[ones(size(sampY)) sampY sampZ]);
%locPrior = dtiSMooth3(locPrior,7);
% TODO: get a location prior.
locPrior = ones(sz);

if(~isempty(b0))
    %% Compute the b0 error.
    % Since the b0 intensity scale is arbitrary, we'll use the info we have so
    % far to get an empirical estimate of the desired b0 range. We assume that
    % the b0 within the target region is roughly uniform, a safe assumption
    % for all white matter regions. 
    %
    % The b0 adds an important check against artifacts, since certain common
    % anatomical features (such as large sinuses) create very low b0 values,
    % but the FA is high and MD is often within the normal tissue range. 
    %
    % Get an initial estimate based on current maps
    img = (1-faErr).*(1-mdErr).*locPrior;
    curGuess = img>finalThresh*0.95;

    % We want to be sure to remove the junk outside the brain. We do
    % that with a hard mask based on normalized b0 intensity.
    brainMask = dtiCleanImageMask(mrAnatHistogramClip(b0,0.4,0.99)>0.4);
    curGuess = curGuess&brainMask;

    mnB0 = mode(b0(curGuess(:)));
    stdB0 = std(b0(curGuess(:)));
    % b0Err is essentially a z-score clipped at ~4SDs and normalized to the 0-1
    % range. We clip and normalize symmetrically (with 'abs').
    b0Err = abs((b0-mnB0)./stdB0);
    if(histClipB0)
       b0Err(b0Err>7) = 7;
       b0Err = b0Err-5;
       b0Err(b0Err<0) = 0;
       b0Err = b0Err./2;
    else
       b0Err(b0Err>5) = 5;
       b0Err = b0Err-1;
       b0Err(b0Err<0) = 0;
       b0Err = b0Err./4;
    end
else
    b0Err = 0;
end
   
%% Compute the final score
wmProb = (1-faErr).*(1-mdErr).*(1-b0Err).*locPrior;

return;
