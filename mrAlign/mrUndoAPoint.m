function [inpts,volpts]=mrUndoAPoint(inpts,volpts)
%function [inpts,volpts]=mrUndoAPoint(inpts,volpts)
%
%Removes the last selected pair of alignment points from the list

%6/16/96	gmb	wrote it.

npoints = size(volpts,1);

inpts=inpts(1:npoints-1,:);
volpts=volpts(1:npoints-1,:);

npoints = size(volpts,1);
disp([num2str(npoints),' pairs of points selected.']);
