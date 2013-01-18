function roi = dtiNewRoi(name, color, coords)
%
% roi = dtiNewRoi(name, color, coords)
%
% HISTORY:
%   2003.10.02 RFD (bob@white.stanford.edu) wrote it.

if(~exist('name','var') || isempty(name))
    name = 'untitled';
end
if(~exist('color','var') || isempty(color))
    color = 'r';
end
if(~exist('coords','var'))
    coords = [];
end

roi.name = name;
roi.color = color;
roi.coords = coords;
roi.visible = 1;
roi.mesh = [];
roi.dirty = 1;
roi.query_id = -1;

return;
