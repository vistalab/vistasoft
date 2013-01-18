function roi = dtiRoiModifyCoords(roi, coords, action, penStyle)
% 
% roi = dtiRoiModifyCoords(roi, coords, [action='add'], [penStyle='default'])
%
% Adds or removes some points (in 'coords') to/from the roi, with some
% sanity checking. clickSize determines how many points will be added per
% 'coord'.
%
%
% HISTORY:
% 2006.11.08 RFD wrote it.

if(~exist('action','var') | isempty(action))
    action = 'a';
else
    action = action(1);
end
if(~exist('penStyle','var')|isempty(penStyle))
    penStyle = 'default';
end
pen = dtiRoiEditGetPen(penStyle);
newCoords = [];
for(ii=1:size(coords,1))
    newCoords = vertcat(newCoords,[coords(ii,1)+pen.x, coords(ii,2)+pen.y, coords(ii,3)+pen.z]);
end
if(action=='a')
    if(isempty(roi.coords))
        roi.coords = unique(newCoords,'rows');
    else
        roi.coords = union(round(roi.coords), round(newCoords), 'rows');
    end
else
    roi.coords = setdiff(round(roi.coords),round(newCoords),'rows');
end

return;