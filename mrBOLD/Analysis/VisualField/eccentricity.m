function ecc = eccentricity(phi, params);
% From corAnal estimated phase (phi), and eccentricity params, 
% compute the estimated eccentricity represented by a voxel or 
% voxels, in visual degrees.
%
% ecc = eccentricity(phi, params);
%
% See retinoSetParams for info on the params struct.
%
% ASSUMPTIONS: This code makes the following assumptions:
% (1) Phi represents an accurate estimate of the zero-crossing point of
%     the best-fitting sinusoid for a given voxel's time series. This 
%     is what computeCorAnal computes, but the co threshold should be
%     reasonable.
% (2) Phi corresponds to the time when the leading edge of a ring stimulus
%     -- if the ring is expanding, the outer edge; if contracting, the 
%     inner edge -- just entered the receptive field of neurons within a 
%     voxel (and so the neurons just started firing, and the hemodynamic 
%     response started rising above the mean). This means the rise time 
%     for the hemodynamic response should be about the same time as the
%     rise time of the sinusoid.
%
% ras, 01/06
if nargin < 2, error('Not enough input arguments.'); end

if isempty(phi), ecc = []; return; end

% check that all necessary fields are assigned
fields = fieldnames(params);
requiredFields = {'startAngle' 'endAngle' 'width' 'blankPeriod'};
if ~all(ismember(requiredFields, fields))
    error('Not all eccentricity params are set. Use retinoSetParams.')
end

% init output eccentricities -- will be same size as phi
ecc = zeros(size(phi));

% if specified, rotate phi mod 2*pi
if checkfields(params, 'startPhase') & params.startPhase~=0
	phi = mod(phi + 2*pi*(1-params.startPhase), 2*pi);
end

% figure out where the leading edge of the stimulus is w.r.t. 
% the center angles specified by startAngle and endAngle. The
% idea here is that the rise time of the hemodynamic response 
% -- which corresponds to the zero-crossing point of the fitted 
% sinsuoid that the corAnal saves, and should be phi -- is 
% determined by the leading edge of the stimulus, rather than
% the center. 
if params.startAngle > params.endAngle
    dirFlag = -1;     % inward-moving stimulus
else
    dirFlag = +1;     % outward-moving stimulus
end

% the dynamic range of the cycle used for mapping eccentricity depends
% on the experimental design -- specifically, if there was a blank period
% the start or end of each cycle, we use the stimulus duty cycle to find 
% this range, but if there was no blank period, or frequency tagging was 
% used, we use the full input range of [0 2pi]. If the duty cycle is used,
% input phi values outside the range will be mapped to 0. 
if isequal(lower(params.blankPeriod), 'start of cycle')
    rng = [2*pi*params.dutyCycle 2*pi];
elseif isequal(lower(params.blankPeriod), 'end of cycle')
    rng = [0 2*pi*(1-params.dutyCycle)];
else
    rng = [0 2*pi];
end
inRange = (phi>=rng(1) & phi<=rng(2));

% mark values not in range as -1
ecc(~inRange) = -1;


% the 'width' field of params can be a single, constant value in 
% degrees, or a 2xN array specifying different widths at different
% time points within a cycle. In the latter case, the first row
% represents time within a cycle (0-2pi), and the second row represents
% width in degrees at that point.  
% Compute the eccentricity separately for each instance:
if length(params.width)==1
    newRange = [params.startAngle params.endAngle]; % + dirFlag*params.width;
    ecc(inRange) = normalize(phi(inRange), newRange(1), newRange(2));
    
else
    xi = params.width(1,:);
    width = params.width(2,:);
    
    % interpolate to find the stimulus center angle at each point in xi
    delta = (params.startAngle - params.endAngle);
    xx = linspace(rng(1), rng(2), length(xi));
    yy = params.startAngle + xx .* delta ./ (2*pi);
    startAngle = interp1(xx, yy, xi);
    
    % subtract out the width at each point
    leadingEdge = startAngle + dirFlag*width;
    
    % now we need to interpolate back into the range
    % represented by phi:
    phiVals = unique(phi);    
    eccVals = interp1(xi, leadingEdge, phiVals);
    for ii = 1:length(eccVals)
        I = find(phiVals==phiVals(i));
        ecc(I) = eccVals(ii);
    end
    ecc(~inRange) = 0;
    
end

return
