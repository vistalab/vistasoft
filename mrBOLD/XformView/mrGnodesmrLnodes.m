function mrLnodes = mrGnodesmrLnodes(mrGnodes);
% 
% mrLnodes = mrGnodes2mrLnodes(mrGnodes);
% 
% AUTHOR:  BW
% DATE:    09.19.99
% PURPOSE:
%   There should be one routine that converts the mrGray nodes
% into mrLoadRet-2.0 nodes. That routine is readGrayGraph.  The code
% here is simply a copy of what is done in readGrayGraph
%         
% mrGray nodes are in [coronal, axial, sagittal] format and
%   run from 0:N-1
% mrLoadRet coords are in [axial, coronal, sagittal] format
%   and run from 1:N
% mrLoadRet nodes are in [coronal, axial, sagittal] format and
%   run from 1:N.  The addition of 1 is implemented in readGrayGraph.
% mrLoadRet ROIs are the same as mrLoadRet coords
%
% SEE ALSO:
%   mrLoadRet2mrGray, readGrayGraph, writeGrayGraph,
%

fprintf('Use readGrayGraph to create mrLoadRet nodes and edges\n');
error;

return;
