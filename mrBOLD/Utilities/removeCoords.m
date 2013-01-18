function coords = removeCoords(coords1,coords2)
%
% coords = removeCoords(coords1,coords2,dims)
%
% Removes coords1 from coords2, used for example to remove
% coordinates from an ROI.
%
% coords, coords1, and coords2: 3xN arrays of (y,x,z) coordinates
% dims is size of volume
%
% djh, 7/98
% djh, 2/2001, dumped coords2Indices & replaced with union(coords1',coords2','rows')
% MMS&AW 1/2005 changed the usage of the setdiff (line 16 and 17) to avoid resorting of the coord order  

if ~isempty(coords1)
    [waste,indx]= setdiff(coords2',coords1','rows');
    coords=coords2(:,sort(indx));
else
    coords=coords2;
end
return
