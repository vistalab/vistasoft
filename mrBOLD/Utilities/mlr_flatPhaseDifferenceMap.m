function diffMap=mlr_flatPhaseDifferenceMap(viewCellArray,scanArray)
% view=mlr_flatPhaseDifferenceMap(viewCellArray,scanArray)
% Purpose:
%    calculates a difference map between the input Flat - one containing
%    the data, the other containing a fitted Atlas. This calculated map
%    are first plotted and then stored in the parameter map of the dataview
%
% Author: Schira (MMS)
% History 
% written 12/14/04 by mark@ski.org, wade@ski.org
% example calls: 
% diffMap=mlr_flatPhaseDifferenceMap({FLAT{3},FLAT{3}},[1 2]);
% diffMap=mlr_flatPhaseDifferenceMap(FLAT{3},[1 2]);
% diffMap=mlr_flatPhaseDifferenceMap({FLAT{1},FLAT{2}},1);
% $Author: wade $
% $Date: 2004/12/16 20:11:00 $



% Much of this routine consists of checks of one sort or another
global dataTYPES;

if (length(viewCellArray)==1)
    viewCellArray={viewCellArray,viewCellArray};
end

if(length(scanArray)==1);
    scanArray=[scanArray,scanArray];
end

if (length(viewCellArray)~=2)
    error('viewCellArray is the wrong size');
end

if (length(scanArray)~=2)
    error('scanArray is the wrong size');
end

hemi1=viewGet(viewCellArray{1}, 'Current Slice');
hemi2=viewGet(viewCellArray{2}, 'Current Slice');

if(hemi1~=hemi2)
    error('Both views must have the same hemisphere selected');
end

hemisphere = hemi1;
map1=viewCellArray{1}.ph{scanArray(1)}(:,:,hemisphere);
map2=viewCellArray{2}.ph{scanArray(2)}(:,:,hemisphere);

% Do a size check on maps. Note that will also stop people from 
% subtracting data on two entirely different flat maps.

if(prod(double(size(map1)==size(map2)))~=1)
    error('Maps are different sizes');
end

if (strcmp(viewCellArray{1}.subdir,viewCellArray{2}.subdir))
    diffMap=map1-map2; % Actually do the differencing
else
    error('You can''t difference maps from two different unfolds');
end
