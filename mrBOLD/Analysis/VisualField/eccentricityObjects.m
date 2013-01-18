function ecc = eccentricityObjects(phi, params);
% From corAnal estimated phase (phi), and eccentricity params, 
% compute the estimated eccentricity represented by a voxel or 
% voxels, in visual degrees, for an object-containing eccentricity
% scan..
%
% ecc = eccentricityObjects(phi, params);
%
% This is a modified version of eccentricity, for a particular
% stimulus run in the KGS lab in which rings containing object
% images contracted / expanded at a nonlinear rate. [...]
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
	phi = mod(phi + (1-params.startPhase), 2*pi);
end

%% recreate the stimulus parameters used during obj_ecc_out
% (if the retino params specify an inward-moving ring, we'll do a flip
%  at the main step)
visAngle = 28.5;
nPositions = 12;
ringWidth = visAngle / (nPositions-1);
tmpStartRadius = linspace(0, visAngle/2-ringWidth, nPositions-1);
endRadius = tmpStartRadius + ringWidth;

% because we actually resized the image rather than squeezing it between
% the start and end radii, the actual start radius is always 1/2 the end
% radius:
startRadius = endRadius / 2;

% leave one blank position, to allow a clear borderline b/w periphery and fovea
startRadius(nPositions) = NaN; endRadius(nPositions) = NaN;


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

% The new range (in deg) for rescaled eccentricity values
newRange = [params.startAngle params.endAngle]; 


%% find phase-to-eccentricity mapping function (yPhi):
% get the sample points xPhi corresponding to the eccentricity yPhi
xPhi = linspace(0, 2*pi, nPositions);

% estimate yPhi at points xPhi:
% instead of the linear step (call to NORMALIZE) in eccentricity,
% here we need a nonlinear mapping. 
% 
% There are a couple of strategies for this mapping; not sure which is right. 
% 
% (1) assume BOLD response increase starts when the leading edge passes;
%	  this will only map to half the total range, so also assume 
%
% (2) assume phi reflects the center of the stimulus in a more linear
%	  manner.
strategy = 'center';  % 'leading edge' or 'center'
switch strategy
	case 'leading edge'
		if dirFlag==-1   % inward moving rings: use inner radius
			leadingEdge = fliplr(startRadius);
		else			 % outward rings: use outer radius
			leadingEdge = endRadius;
		end
		
		% the "twelfth" position in these stimuli indicates a blank screen,
		% which separates the most peripheral and most foveal rings.
		% Realistically, we get phases corresponding to this part of the
		% cycle. In this mapping, we assume these phases reflect stimuli
		% that are more peripheral (just a guess, haven't come up with a 
		% completely principled reason for this).
		leadingEdge(leadingEdge==0) = max(newRange);
		
		yPhi = leadingEdge;
		
	case 'center'
		if dirFlag==-1   % inward moving rings: use inner radius
			center = fliplr(startRadius + endRadius ./ 2);
		else			 % outward rings: use outer radius
			center = startRadius + endRadius ./ 2;
		end
		
		% pad the 'blank' position as the max center value
		center(center==0) = max(newRange);
		
		yPhi = center;  % simple linear mapping
end


%% main step:
% interpolate to get the estimated eccentricity values
ecc(inRange) = interp1( xPhi, yPhi, phi(inRange), 'linear' );

return
