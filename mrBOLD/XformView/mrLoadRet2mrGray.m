function mrGnodes = mrLoadRet2mrGray(coords);
% 
%     mrGnodes = mrLoadRet2mrGray(coords);
% 
% AUTHOR:  Wandell
% DATE:    12.1.99
% PURPOSE:
%   There should be one routine that converts the coords
% in mrLoadRet-2.0 format into mrGray node locations. This is that routine.
% CAUTION:  mrGnodes is not an 8xN structure required for
%           a real gray graph with nodes.  The mrGnodes is only
%           the first three rows (the locations) of the nodes.
%        
% mrGray nodes are in [coronal, axial, sagittal] format and
%   run from 0:N-1
% mrLoadRet coords are in [axial, coronal, sagittal] format
%   and run from 1:N
% mrLoadRet nodes are in [coronal, axial, sagittal] format and
%   run from 1:N.  The addition of 1 is implemented in readGrayGraph.
% mrLoadRet ROIs are the same as mrLoadRet coords
%
% See also:  readGrayGraph, loadGrayNodes, mrGnodes2mrLcoords
% 
% BW:  Edited comments 12.1.00

if size(coords,1) ~= 3
   error('mrLoadRet2mrGray:  Input coords must be 3xN.');
end

mrGnodes = [coords(2,:); coords(1,:); coords(3,:)] - 1;

return;
