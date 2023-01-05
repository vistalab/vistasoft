function mrLnodes = mrLcoords2mrLnodes(mrLcoords)
%
%         mrLnodes = mrLcoords2mrLnodes(mrLcoords)
%
% AUTHOR:  Wandell
% DATE:  12.1.00
% PURPOSE:
%  Convert mrLoadRet coords to mrLoadRet node locations.  But the rest of
% the nodes structure is not created because we don't have the edge information.
% This routine is mainly a reminder about the relationship between node and coord
% values.  It should only be used by a pro ...
%    
% mrGray nodes are in [coronal, axial, sagittal] format and
%   run from 0:N-1
% mrLoadRet coords are in [axial, coronal, sagittal] format
%   and run from 1:N
% mrLoadRet nodes are in [coronal, axial, sagittal] format and
%   run from 1:N.  The addition of 1 is implemented in readGrayGraph.
% mrLoadRet ROIs are the same as mrLoadRet coords
%
% BW

% Assigning only the coordinate entries of nodes.  Remember that
% nodes is 8 x N.  This routine probably shouldn't exist.
%
fprintf('Returning [cor,ax,sag] dimensions of coords (full node representation is 8xN)\n');
% fprintf('You probably want to read the nodes directly from a gray graph file.\n');
% fprintf('Only use this routine if you know what you are doing.\n');
mrLnodes([1:3],:) = mrLcoords([2,1,3],:);

return;
