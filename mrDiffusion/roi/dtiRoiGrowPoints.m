function seeds = dtiRoiGrowPoints(hullRoi, seeds)
%
% grownRois = dtiRoiGrowPoints(hullRoi, seeds)
%
% Grows N new ROIs from a set of N seed points to fill the hullRoi. seeds 
% can either be an Nx3 array of seed points or a set of N roi structs that each 
% contain exactly on coordinate in the 'coord' field. If the later, then the 
% grownRois will inherit the other field values (name, color, etc) from the
% seeds rois.
%
% HISTORY:
% 2009.08.18 RFD wrote it.


if(~isstruct(seeds))
    colors = 'rmbcgy';
    pts = seeds;
    clear seeds;
    for(ii=1:size(pts,1))
        name = sprintf('grownRoi_%03d',ii);
        color = colors(mod(ii-1,numel(colors))+1);
        seeds(ii) = dtiNewRoi(name, color, pts(ii,:));
    end
end

hullCoords = hullRoi.coords;

for(ii=1:numel(seeds))
    nearest = nearpoints(seeds(ii).coords', hullCoords');
    coords{ii} =  nearest;
    % remove this point from the global pool
    hullCoords(nearest,:) = Inf;
end

while(any(hullCoords(:,1)~=Inf))
    % Grow each by taking the coordinates that are nearest any points currently included
    for(ii=1:numel(seeds))
        [nearest,distSq] = nearpoints(hullRoi.coords(coords{ii},:)', hullCoords');
        %nearest = nearest(distSq<=5);
        coords{ii} =  unique([coords{ii} nearest]);
        % remove this point(s) from the global pool
        hullCoords(nearest,:) = Inf;
    end
end
% NOTE: this will be biased due to the order of 'seg'. E.g., for callosal ROIs
% the genu will take priority over the others. If we assume that they are 
% in order (anterior-posterior), then we can do it again in the reverese 
% order and compare the two results to find the contentions coords. Then, we
% can do something with them (e.g., eliminate them, randomly assign, etc.)

for(ii=1:numel(seeds))
    seeds(ii).coords = hullRoi.coords(coords{ii},:);
end

return;

