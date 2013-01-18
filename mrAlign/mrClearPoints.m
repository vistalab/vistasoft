function [inpts,volpts]=mrClearPoints(inpts,volpts)
%function [inpts,volpts]=mrClearPoints(inpts,volpts)
%
%Clear all alignment points

%6/16/96	gmb	wrote it.

ynstr=input('Clear all points (y/n)? ','s');

if ynstr(1)=='y'
	inpts=[];
	volpts=[];
end

npoints = size(volpts,1);
disp([num2str(npoints),' pairs of points selected.']);

