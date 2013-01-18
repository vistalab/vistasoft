function area = measureFlatROIArea(flatView)
%
% area = measureFlatROIArea(flatView)
%
% AUTHOR:  Dougherty
% DATE:    09.13.99
% PURPOSE:
%
% Measures the area on the 3D cortical surface of the current 
% flat-map ROI.  
% 
%    1. Select ROI in the Flat window.
% 
%    2. Use the Area Measure pull down in the Analysis pulldown of
% the Flat window.  
% 
% NOTE: this code relies on the assumption that the FLAT.coords
% are sorted such that the first pair of duplicated coordinates
% corresponds to the coordinates of the layer 1 node.  This
% assumption seems to hold true, but puts us at the mercy of those
% who maintain the FLAT.coords data structure!  A more robust
% algorithm would explicity find the layer nodes by grabbing
% VOLUME.nodes and looking htere.
% 
% See Also: sumTriangularArea 
%
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH
% 2006.04.10 RFD: Added warning to use the new and improved
% measureFlatROIAreaMesh instead. The algorith implemented below tries to
% create it's own triangulation based on layer 1 nodes. This usually works
% OK for ROIs that are convex, but can severely over-estimate the area when
% the ROI has concavities. 

warning('This function is obsolete (and not very accurate)- use measureFlatROIAreaMesh instead!');

global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% If someone want the area returned, then we assume that we are scripted
% and thus don't use gui stuff.
if(nargout==0)
    gui = 1;
else
    gui = 0;
end

% Check some flat and volume stuff here when you
% get a chance to fix this code up

% Get a gray structure because we need the gray nodes.
grayView = getSelectedGray;
if isempty(grayView)
    grayView = initHiddenGray;
end

% Get selpts from current ROI
if flatView.selectedROI
  ROIcoords = getCurROIcoords(flatView);
else
  error('No current ROI');
end

if isempty(ROIcoords)
  error('ROI is empty!');
end

% Find gray matter nodes that are within the ROI
volCoords = [];
flatCoords = [];
flatImSize = flatView.ui.imSize;
hemi = ROIcoords(3,1);
if any(ROIcoords(3,:) ~= hemi)
   error('ROI spans both hemispheres!');
end
ROIcoords = ROIcoords([1:2],:);
ROIIndices = coords2Indices(ROIcoords,flatImSize);
flatIndices = coords2Indices(round(flatView.coords{hemi}),flatImSize);
% This works because flatIndices is rounded to integers. Ill-formed ROIs,
% such as those that are spotty or have holes won't work very well.
bothIndices = intersect(flatIndices,ROIIndices);
flatRoiIndices = zeros(size(flatIndices));
for id = 1:length(bothIndices)
    % we now loop to find all the matching flatIndices. We need to do this
    % because intersect doesn't give us duplicates. So, we build the real
    % list ourselves.
   flatRoiIndices = flatRoiIndices | (flatIndices == bothIndices(id));
end
   
% WE NEED TO MAKE SURE THAT WE GET ONLY LAYER 1 NODES

% if(hemi==1)
%     eval('flatMat = load(flatView.leftPath)', 'flatMat = [];');
% else
%     eval('flatMat = load(flatView.leftPath)', 'flatMat = [];');
% end
% if(~isempty(flatMat))
%     % Alex Wade tells me that this field in the flat.mat data struct
%     % indicates how many layer one nodes there were. Further, the nodes are
%     % sorted so that all layer one nodes come first. We can use these two
%     % bits of info to recover the layer one nodes. Alas, it appears that
%     % this sorted order is lost somewhere along the line when the flat data
%     % are computed from the flat.mat file.
%     layerOneIndices = [1:flatMat.infoStr.numNodes.num(1)];
%     volCoords = flatView.grayCoords{hemi}(:,flatRoiIndices);
%     flatCoords = flatView.coords{hemi}(:,flatRoiIndices);
% else
%     warning('Could not find the flat.mat file (check your paths)- reverting to old layer-one node method.');
% end
volCoords = flatView.grayCoords{hemi}(:,flatRoiIndices);
flatCoords = flatView.coords{hemi}(:,flatRoiIndices);
% It should be safe to assume that when flatCoords contains
% duplicates, the first corresponds to layer 1.
temp = unique(flatCoords','rows')';
% unique doesn't always return the first instance, so we'll
% find the first instances ourselves
layerOneIndices = [];
for ii=1:size(temp,2)
    curInd = find(flatCoords(1,:)==temp(1,ii)&flatCoords(2,:)==temp(2,ii));
    layerOneIndices = [layerOneIndices, curInd(1)];
end
% extract layer 1 nodes:
flatCoords = flatCoords(:,layerOneIndices);
volCoords = volCoords(:,layerOneIndices);

if size(flatCoords,2)<3
    if(gui)
        msgbox('ROI too small- fewer than 3 flatCoords were captured!');
    end
   disp('ROI too small- fewer than 3 flatCoords were captured!');
   area = 0;
   return;
end

triangles = triangulateRegion(flatCoords(2,:), flatCoords(1,:), ...
   			ROIcoords(2,:), ROIcoords(1,:));
%triangles = delaunay(flatCoords(2,:), flatCoords(1,:));

% Now we have triangles for the ROI on the flat map.
% The triplets in 'triangles' are indices into flatCoords.
% Because flatCoords map directly onto volCoords, we now have 
% triangles for the 3D surface.
% Just one complication- the coordinates in volCoords are on
% the integer vAnatomy grid.  We need to scale them by the
% actual voxel size before computing area.
volCoords = volCoords.*repmat(mmPerPix',1,size(volCoords,2));

[volArea,volAreaList] = sumTriangularArea(triangles, volCoords);
[flatArea,flatAreaList] = sumTriangularArea(triangles, flatCoords);
ROIname = flatView.ROIs(flatView.selectedROI).name;
areaStr = ['Triangulated area of ' ROIname ' is ' num2str(volArea) ' mm^2 '...
      '(flat area is ' num2str(flatArea) ' mm^2, ROI contains ' ...
      num2str(size(ROIcoords,2)) ' voxels and ' ...
      num2str(size(volCoords,2)) ' layer 1 gray nodes.)'];
disp(areaStr);
% if(gui)
%     msgbox([areaStr],[ROIname ' area']);
% end

if(gui)
    diffScore = abs(volAreaList-flatAreaList);
    scaleFact = max(diffScore);
    colors = diffScore./scaleFact;
    figure;
    colormap(jet);
    caxis([0 1]);
    patch([flatCoords(2,triangles(:,1)');flatCoords(2,triangles(:,2)');...
          flatCoords(2,triangles(:,3)')], ...
        -[flatCoords(1,triangles(:,1)');flatCoords(1,triangles(:,2)');...
          flatCoords(1,triangles(:,3)')],colors');
    colorbar;
    hold on;
    plot(ROIcoords(2,:), -ROIcoords(1,:), 'sk');
    hold off;
    axis equal;
    title(areaStr);
end
area = volArea;
return;

%flatView.ROIs(flatView.selectedROI).area = area;
figure;
h = trisurf(triangles,volCoords(3,:),volCoords(1,:),volCoords(2,:),zeros(size(volCoords(1,:))));
view(3); daspect([1,1,1]); axis tight
shading interp; colormap(gray);
camlight right; lighting phong;
title(areaStr);
