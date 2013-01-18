function [basePhase, phaseRange] = atlasWedgePhases(visualField)
%
%   [basePhase, phaseRange] = atlasWedgePhases(visualField)
%
% Author: Wandell
% Purpose:
%   For an entire wedge atlas, the phase range and base phase differ
%   depending on the visual field representation.  This routine returns the base
%   phase and the phase range.  This information is used in atlas creation
%   at several points.  By having the phase values set here, we can keep
%   them consistent across various subroutines.
%
%   visualField is a cell array describing all the visual field
%   representations in the atlas.  For example 
%   visualField{1} = 'hemifield', visualField{2} = 'lowerquarterfield'
%
%   clear visualField; visualField{1} = 'uqf';
%   clear visualField; visualField{1} = 'lqf';
%   clear visualField; visualField{1} = 'hemifield';
%
%      atlasWedgeMinPhase(visualField)

% We make the phase range a little bigger than absolutely necessary at this
% point.  Maybe we should zero this out.
extraPhase = pi/8;  
extraPhase = 0;  

if isstr(visualField)
    tmp = visualField;
    clear visualField;
    visualField{1} = tmp;
end

% We test for an [uqf,lqf,hemi]
tst = [0,0,0];

for ii=1:length(visualField)
    
    switch lower(visualField{ii})
        case {'upperquarterfield','uqf'}
            tst(1) = 1;
        case {'lowerquarterfield','lqf'}
            tst(2) = 1;
        case {'hemifield','hemi','hemifield+'}
            tst(3) = 1;
    end
end

if tst(3) | (tst(1) & tst(2))
    % Hemifield or both upper and lower in the list
    phaseRange = pi  + extraPhase;
    basePhase = pi/2 - extraPhase/2;
elseif tst(1)
    % Only upper in the list
    phaseRange = pi/2 + extraPhase/2;
    basePhase = pi/2 - extraPhase/4;
elseif tst(2)
    % Only lower in the list
    phaseRange = pi/2 + extraPhase/2;
    basePhase = pi - extraPhase/4;
end

return;

% %
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