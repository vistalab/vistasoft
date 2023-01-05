function vw = inplaneMotionComp(vw,scan,baseFrame)
%
% vw = inplaneMotionComp(vw,scan,baseFrame)
%
% Performs inplane motion compensation (by calling inplaneMotionCompSeries)
% on each slice.
%
% scanNum: default current scan
% baseFrame: default 1
%
% If you change this function make parallel changes in:
%   betweenScanMotComp, inplaneMotionComp
%
% djh, 4/16/99

if ~exist('scan','var'),        scan      = viewGet(vw, 'curscan'); end
if ~exist('baseFrame','var'),   baseFrame = 1;                      end

slices = sliceList(vw,scan);

% make backup copy of tSeries to origTSeries
copyOrigTseries(vw,scan);

for slice = slices
   vw = inplaneMotionCompSeries(vw,scan,slice,baseFrame);
end