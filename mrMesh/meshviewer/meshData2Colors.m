function colors = meshData2Colors(data, cmap, range, scaleFlag);
%
%   colors = meshData2Colors(data, cmap, range, [scaleFlag]);
%
% Author: Ress
% Purpose:
%     Create a set of colormap data that correspond to each input value.  The
% color map indices are scaled to account for the indput range and the size
% of the color map.
%
% scaleFlag: if 1, will scale the data to fit the input range; otherwise,
% don't scale at all.

% Edit History:
%
% This routine is oddly named, no?  It makes colors, it doesn't make
% indices.  Once we are sure about this, let's change the call to something
% like meshData2Colors(data,cmap,range).  (BW).
%
% 02/04 Agreed--adapted this from MakeCMapIndices, included option to not
% scale the data (e.g. if you have a discrete number of values on your map, 
% with a corresponding # of colors on the cmap). -ras
%
% 2005.08.11 RFD: passing an empty range now has the same effect as scaleFlag=0 
%
% 07/06 ras: updated the way NaNs are handled: before they were ignored,
% and so if data had NaNs, colors wouldn't have the same # of columns as
% data. Now, NaN values are mapped to the first color mapped, so they're
% the same size. Other code, like meshOverlay (new) and meshColorOverlay
% (old), should be used to re-map these NaN vertices with something like
% curvature.

if ~exist('scaleFlag','var')    scaleFlag = 1;      end
if isempty(range),		
	range = [nanmin(data) nanmax(data)];
end

% if the data are empty (e.g., we're in anat mode and just want to view
% the ROIs), don't do this.
if isempty(data) | sum(data)==0
    colors = zeros(3, length(data));
    return; 
end

% Number of colors in the color map.
nMap = max(size(cmap));

% initialize colors
colors = repmat(cmap(:,1), [1 length(data)]);

if scaleFlag==1
    % ignore NaNs by mapping to the first cmap entry (it'll be up to 
    % the user / whatever code calls this to set these NaN values to 
    % a different color, like curvature: see meshOverlay)
    data(isnan(data)) = range(1);    
    
    % scale data into number of colors in map:
    cmapIndices = rescale2(data, range, [1 nMap]);    
    
    % now map colormap to each data point, given the color map:
    colors = cmap(:,cmapIndices);
else        
    % don't scale.
    vals = unique(data(data>0)); % the unique (non-zero) data in the data
    nDataVals = length(vals); 
    whichInds = round(linspace(1,nMap,nDataVals));
    
    % for each unique value in the data, manually
    % look up the proper color. This should only
    % be used for maps with a small number of 
    % distinct colors (like multiple overlays), 
    % otherwise this takes a long time to run through:
    cmapIndices = ones(size(data)); 
    for i = 1:nDataVals
        cmapIndices(data==vals(i)) = whichInds(i);
    end
    
	colors = cmap(:,cmapIndices);
end


return

