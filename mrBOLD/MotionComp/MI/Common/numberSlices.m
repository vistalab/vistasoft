function nSlices = numberSlices(view,scan)
%
%    gb 03/31/05
%
%  Returns the number of the slices in the inplane view
%
nSlices = size(view.anat,3);