function [inpts,volpts] = mrGetAlPtOblVol(inpts,volpts,retwin,volwin,Zinp,obPts,obSize);
%
% mrGetAlignPoint
%
%     [inpts,volpts] = mrGetAlPtOblVol(inpts, volpts, retwin, volwin, Zinp, obSize);
%
%	Gets a point from the inplane and from the sagittal antomies.
%	Needs the z coordinates of inplane passed in.

npoints = size(volpts,1)+1;
figure(retwin);
tmp = mrGinput(1,'cross');
tmp(3) = Zinp;
inpts(npoints,:) = tmp;
figure(volwin);
tmp = mrGinput(1,'cross');
obcoord = round(tmp(2) +round(tmp(1)-1)*obSize(1));
volpts(npoints,:) = obPts(obcoord,:);

