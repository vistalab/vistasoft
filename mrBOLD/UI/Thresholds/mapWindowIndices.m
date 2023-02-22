function id = mapWindowIndices(map,mapWindow)
%
% id = mapWindowIndices(map,mapWindow)
%
% Returns indices of vector map within mapWindow
%
% if mapWindow(1)<mapWindow(2) returns mapWindow(1) <= map <= mapWindow(2)
% if mapWindow(1)>mapWindow(2) returns map >= mapWindow(1) or map <= mapWindow(2)
%
% djh, 7/98

if diff(mapWindow)>0
  id = find(map>=mapWindow(1) & map<=mapWindow(2));
else
  id = find(map>=mapWindow(1) | map<=mapWindow(2));
end

