function inplane = flat2ipCurROI(flat,inplane,volume)
%
% inplane = flat2ipAllROIs(flat,inplane,[volume])
%
% Author: AAB/BW
%   Transform ROIs from flat view to inplane, going through the volume
%   representation.
%
% Examples:
%    INPLANE{1} = flat2ipAllROIs(FLAT{4},INPLANE{1});
%

if ieNotDefined('volume'), volume = initHiddenGray; end

volume = flat2volCurROI(flat,volume);
inplane = vol2ipCurROI(volume,inplane);

return;

