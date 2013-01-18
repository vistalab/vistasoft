function ph = atlasUndoPhase(atlasParams, ph)
%
%      ph = atlasUndoPhase(atlasParams, ph)
%
% Purpose:
%   Convert the atlas phase data by shifting their phase and scaling the
%   phase range.  The amount of shifting and scaling is stored in the
%   phaseShift/phaseScale fields.  I am not sure why this code is used at
%   all.  I think we should be using shiftPhase instead and this is left
%   over from version 1.0.  I am trying to get rid of it -- BW 
%
% HISTORY:
% 2003.08.29 RFD (bob@white.stanford.edu) got tired of duplicating this
% code, so here's a simple function.

warning('atlasUndoPhase is obsolete.')

% Checking.
if(length(atlasParams) ~= length(ph) | length(atlasParams(1).phaseShift) ~= size(ph{1},3))
    warning('atlasParams and ph should have the same number of scans and slices!');
end

%  Create a scaled and shifted version of the atlas parameters.
for(scan=1:length(atlasParams))
    for(slice=1:length(atlasParams(scan).phaseShift))
        ph{scan}(:,:,slice) = mod((squeeze(ph{scan}(:,:,slice)) ...
            - atlasParams(scan).phaseShift(slice)) / atlasParams(scan).phaseScale(slice), 2*pi);
    end
end


return;