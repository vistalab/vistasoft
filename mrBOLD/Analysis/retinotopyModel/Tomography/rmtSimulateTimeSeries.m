function [ts prf]=rmtSimulateTimeSeries(stimulus,tr,prf,hrf)
% rmtSimulateTimeSeries - make fMRI time series given a particular stimulus
%
% ts=rmtSimulateTimeSeries(stimulus,[tr],[prf],[hrfparams])
%
% Input:
%     stimulus: 3D matrix (spacexspacextime)
%     tr      : scanner repetition time (seconds) [optional]
%     prf     : population receptive fields (spacexdifferent_prfs)
%               [optional]
%     hrf     : hrf parameters (hrf.type and hrf.params) [optional]
%               see rfConvolveTC.m
%
% 2010/09 SOD: wrote it.

%--- input check and conversions
if ~exist('stimulus','var') || isempty(stimulus)
    error('Must give stimulus matrix');
end
if ~exist('tr','var') || isempty(tr)
    tr = 1.5;
end
if ~exist('hrf','var') || isempty(hrf)
    % see rfConvolveTC for other params
    hrf.type = 't';
    hrf.params = [5.4 5.2 10.8 7.35 0.35];
end
% reshape stimulus from 3D to 2D
if numel(size(stimulus))==3
    sz = size(stimulus);
    stimulus = reshape(stimulus,[sz(1).*sz(2) sz(3)]);
end
% make pRF is it does not exist (we need the stimulus dimensions)
if ~exist('prf','var') || isempty(prf)
   prf = makeSomeRandomPRFs(sqrt(size(stimulus,1)));
end

%--- actual predictions

% make predicted timeseries
ts = stimulus'*prf;

% convolve with hrf
ts = rfConvolveTC(ts, tr, hrf.type, hrf.params);

%--- for output reshape prf
sz  = size(prf);
prf = reshape(prf,[[1 1]*sqrt(sz(1)) sz(2)]);

return
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function prf=makeSomeRandomPRFs(sz)
% Well.. we don't actually make random ones but a semi-balanced set:
% 1) a small one, 2) a large one, 3) an oval, 4) DoG, 5) circle
% though we could make random ones.

% make coordinate system
[X,Y]=meshgrid(linspace(-1,1,sz));

% turn into 1D for output
X=X(:); Y=Y(:);

% define Gaussians
sigmaMajor = [0.1 1  0.3  0.3  0.6];
sigmaMinor = [0.1 1  0.1  0.3  0.6];
theta      = [0   0  0    0    0  ];
x0         = [0.4 0 -0.2 -0.5 -0.5];
y0         = [0   0 -0.2 -0.5 -0.5];

% make the 5 different Gaussians
prf = rfGaussian2d(X,Y,sigmaMajor,sigmaMinor,theta,x0,y0);

% (crude) normalize to same volume
prf = prf ./ (ones(size(prf,1),1)*sum(prf));

% combine the 4 & 5'th to a difference of gaussians
prf(:,4) = prf(:,4) - prf(:,5);

% replace the 5th with a hard-edge circle
c = makecircle(sz./3,sz);
c = c ./ sum(c(:));
prf(:,5) = c(:);

return
%--------------------------------------------------------------------------







