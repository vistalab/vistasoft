function id = phWindowIndices(ph,phWindow)
%
% id = phWindowIndices(ph,phWindow)
%
% Returns indices of vector ph within phWindow
%
% if phWindow(1)<phWindow(2) returns phWindow(1) <= ph <= phWindow(2)
% if phWindow(1)>phWindow(2) returns ph >= phWindow(1) or ph <= phWindow(2)
%
% djh, 7/98

if diff(phWindow)>0
  id = find(ph>=phWindow(1) & ph<=phWindow(2));
else
  id = find(ph>=phWindow(1) | ph<=phWindow(2));
end

