function [inpts,volpts] = mrGetAlPtSagVol(inpts, volpts, retwin, volwin, Zinp, Zsag);
%
% mrGetAlignPoint
%
%     [inpts,volpts] = mrGetAlPtSagVol(inpts, volpts, retwin, volwin, Zinp, Zsag);
%
%	Gets a point from the inplane and from the sagittal antomies.
%	Needs the z coordinates of each passed in as arguments.

npoints = size(volpts,1)+1;
figure(retwin);
tmp = myGinput(1,'cross');
tmp(3) = Zinp;
inpts(npoints,:) = tmp;
figure(volwin);
tmp = myGinput(1,'cross');
tmp(3) = Zsag;
volpts(npoints,:) = tmp;

