function [stdAtlasE, stdAtlasA,atlasCorners] = atlasCreateStandard(visualField,retPhase,resolution)
%
%   [stdAtlasE, stdAtlasA,atlasCorners] = atlasCreateStandard(visualField,retPhase)
%
% Author: Wandell
% Purpose:
%    We create a standard pair of phase maps on a square.
%    The expanding ring phases returned run from [0,maxPhase] where
%    maxPhase is set by the retPhases value.
%
%    The rotating wedge phases fall within the range from (pi/2 - delta) to (3pi/2) + delta.
%    The phases span either a full pi (hemifield) or just a pi/2 (quarterfield).
%    The phase range is set to match the upper (pi/2,pi) and lower
%    (pi,3pi/2) quarterfields assuming a clockwise rotation of the
%    stimulus.
%History:
%01/08/04 Schira (mark@ski.org) added resolution in the data input and nargin at line 20
 


if nargin==2
    resolution=256;
end

if ieNotDefined('visualField'), error('Specify visual hemi/lower/upper quarterfield.'); end
if ieNotDefined('retPhase'), error('We need the retinotopy phase variables.'); end

stdAtlasA = zeros(resolution,resolution);
stdAtlasE = zeros(resolution,resolution);

% The user sets the expanding ring range based on the choices of the
% retinotopy phases.
retPhaseShift = shiftPhase([retPhase(1),retPhase(2)],-retPhase(1));
maxPhase = retPhaseShift(2);
fprintf('Using a total phase of %.1f\n',maxPhase);

% The phase values are set to be an accelerating function so we get more
% central phases than peripheral phases.  This is an imprecise version of cortical
% magnification.
phaseValues = [0:resolution-1]/resolution;
%phaseValues = phaseValues.^2;

for ii=0:(resolution-1)
    stdAtlasE(ii+1,:) = phaseValues(ii+1)*maxPhase;
end

% The hemifield angular atlas runs from pi/2 to 3pi/2.
% The upper and lower quarterfields are symmetric around pi.
[basePhase, phaseRange] = atlasWedgePhases(visualField);

% % Putting them here has to do with RFD's original code.
% %-------------------------------------------
% % We are experimenting with putting in a little more phase at the margin
% % All this code should call atlasWedgeMinPhase
% extraPhase = pi/8;  
% %-------------------------------------------
% switch lower(visualField)
%     case {'hemifield','hemifield+'}
%         phaseRange = pi  + extraPhase;
%         basePhase = pi/2 - extraPhase/2;
%     case 'upperquarterfield'
%         phaseRange = pi/2 + extraPhase/2;
%         basePhase = pi/2 - extraPhase/4;
%     case 'lowerquarterfield'
%         phaseRange = pi/2 + extraPhase/2;
%         basePhase = pi - extraPhase/4;
%     otherwise
%         error('Unknown visual field type');    
% end

for ii=0:(resolution-1)
    stdAtlasA(:,ii+1) = (ii/resolution)*phaseRange + basePhase;
end


% Note the atlas corners.  The boundary from 
%   (1,1) to (128,1) is the foveal lin3
%   (128,128) to (1,128) is the peripheral line.
%   (128,1) to (128,128) should be the LVM line
%   (1,1) to (1,128) the UVM line
%
atlasCorners = [1, 1; ...
        resolution,1; ...
        resolution, resolution; ...
        1, resolution];

return;
