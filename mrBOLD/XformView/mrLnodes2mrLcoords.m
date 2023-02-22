function mrLcoords = mrLnodes2mrLcoords(mrLnodes)
%
%    mrLcoords = mrLnodes2mrLcoords(mrLnodes)
%
% AUTHOR:  Wandell
% DATE:  12.1.00
% PURPOSE:
%     
% mrGray nodes are in [coronal, axial, sagittal] format and
%   run from 0:N-1
% mrLoadRet coords are in [axial, coronal, sagittal] format
%   and run from 1:N
% mrLoadRet nodes are in [coronal, axial, sagittal] format and
%   run from 1:N.  The addition of 1 is implemented in readGrayGraph.
% mrLoadRet ROIs are the same as mrLoadRet coords
%
% see also:  mrGray2mrLoadRet

mrLcoords = mrLnodes([2,1,3],:);

return;
