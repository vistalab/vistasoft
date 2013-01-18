function roi = dtiRoiMakePlane(cornerCoords, roiName, roiColor)
%
% roi = dtiRoiMakePlane(cornerCoords, name, color)
%
% e.g.: 
% roi = dtiRoiMakePlane([-60,-30,-60; 60,-30,80], 'coronal_plane', 'c')
%
% For a more complex sample, edit this function to see the code below the
% return.
% 
% 2008.10.01 RFD: wrote it.

if(~exist('roiName','var') || isempty(roiName))
    roiName = 'plane';
end
if(~exist('roiColor','var') || isempty(roiColor))
    roiColor = 'r';
end
lc = min(cornerCoords);
uc = max(cornerCoords);
[x,y,z] = ndgrid([lc(1):uc(1)], [lc(2):uc(2)], [lc(3):uc(3)]);

roi = dtiNewRoi(roiName, roiColor, [x(:),y(:),z(:)]);

return;



% To run this on a bunch of subjects:
bd = '/biac3/wandell4/data/reading_longitude/dti_y4';
[subList,subCodes,subDirs] = findSubjects(fullfile(bd,'/*'),'dti06');
x = [-70 70];
z = [-60 80];
y = [-30 -31 -34 -30 ];
for(ii=1:numel(subList))
    roi = dtiRoiMakePlane([x(1),y(ii),z(1); x(2),y(ii),z(2)], 'coronal', 'c');
    roiFileName = fullfile(subDirs{ii},'ROIs','IPSproject','coronal');
    dtiWriteRoi(roi,roiFileName);
end