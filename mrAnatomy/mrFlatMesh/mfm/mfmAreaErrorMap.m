function [areaErrorMap,meanX,meanY] = mfmAreaErrorMap(unfoldMesh,nFaces,unfolded2D,errorList)
%
%  [areaErrorMap,meanX,meanY] = mfmAreaErrorMap(unfoldMesh,nFaces,errorList)
%
%Author: Wandell
%Purpose:
%   Compute the area distortions.  Extracted from ARW code.
%

Xcogs=unfolded2D(unfoldMesh.uniqueFaceIndexList(:),1);
Xcogs=reshape(Xcogs,nFaces,3);
meanX=mean(Xcogs,2);

Ycogs=unfolded2D(unfoldMesh.uniqueFaceIndexList(:),2);
Ycogs=reshape(Ycogs,nFaces,3);
meanY=mean(Ycogs,2);
areaErrorMap=flipud(makeMeshImage([meanY(:),meanX(:)],errorList,128));

return;