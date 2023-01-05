function dataTYPES = dtCopy(from,to,scanList,slice,wedgeRingPhaseShifts,retPhases)
%
%    dataTYPES = dtCopy(from,to,scanList,slice,wedgeRingPhaseShifts,retPhases)
%
% Author:  Wandell
% Purpose:
%   Copy one dataTYPES entry to another.
%   Used in createAtlas.  The functionality exists in other places.  So, I broke it out
%   here to see if it will prove useful down the road.
%

global dataTYPES;

nAtlases = length(scanList);
if ieNotDefined('wedgeRingPhaseShifts'), wedgeRingPhaseShifts(1:nAtlases) = 0; end

for(ii=1:nAtlases)
    dataTYPES(to).scanParams(ii)            = dataTYPES(from).scanParams(1);
    dataTYPES(to).blockedAnalysisParams(ii) = dataTYPES(from).blockedAnalysisParams(1);
    dataTYPES(to).eventAnalysisParams(ii)   = dataTYPES(from).eventAnalysisParams(1);
    
    % Change the name to something meaningful
    dataTYPES(to).scanParams(ii).annotation = [scanList{ii},' atlas'];
    
    % This is the phase shift between the standard atlas, for wedges
    % [pi/2,3pi/w] and for rings, [0, 2pi] versus the phases of 
    % the atlas we have constructed that matches the data.
    % 
    % We put the wedge atlas in the first slice and the ring atlas in the
    % 2nd slice.  So, wedgeRingPhaseShifts should be those two phase
    % shifts.
    dataTYPES(to).atlasParams(ii).phaseShift(slice) = wedgeRingPhaseShifts(ii);
    dataTYPES(to).atlasParams(ii).phaseScale(slice) = 1;
    
    % The phaseShift variable above should become obsolete which will
    % require changes in various pieces of code.  We are leaving it in for
    % the mean time.  But we should start replacing all instances of the
    % phaseShift by using the appropriate retPhases value.
    % The retPhases is a four vector that contains the 
    % [foveal, peripheral,lower vertical field, upper vertical field] phases.
    dataTYPES(to).atlasParams(ii).retPhases(slice,:) = retPhases;

end

return;