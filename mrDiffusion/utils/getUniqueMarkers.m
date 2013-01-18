function markers = getUniqueMarkers(N)
%Generate N unique markers (combination of color and shape) for plotting
%
% markers = getUniqueMarkers(N)
%
% Input: How many markers you want. 91 is max. Output: an array of strings
% that can be used as a "LineSpec" parameter (line style not included)

% HISTORY: ER wrote it 03/2010

%MarkerEdgeColors={'b', 'c' 'g' 'k' 'm' 'r', 'y'};
%MarkerShapes={'*', '+', '.', '<', '>', '^', 'd', 'h', 'o', 'p', 's','v','x'}; %MORE OPTIONS
MarkerEdgeColors={'b', 'c' 'g' 'w' 'm' 'r', 'y'};
MarkerShapes={'*', '+', '^', 'd',  'o', 'p', 's','x'};

if N > length(MarkerEdgeColors)*length(MarkerShapes)
    error(['N can not exceed ' num2str(length(MarkerEdgeColors)*length(MarkerShapes))]);
end

markerIDs = randsample(length(MarkerEdgeColors)*length(MarkerShapes), N);
[MarkerEdgeColorIDs, MarkerShapeIDs] = ind2sub([length(MarkerEdgeColors) length(MarkerShapes)], markerIDs);
markers = cellstr([char(MarkerEdgeColors(MarkerEdgeColorIDs)') char(MarkerShapes(MarkerShapeIDs)')]);
