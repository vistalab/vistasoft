function [view,area3d] = measureFlatROIAreaMesh(view, grayThickness)
%
% [view,area3d] = measureFlatROIAreaMesh(view, [grayThickness])
%
% Measures the area on the 3D cortical surface of the current 
% flat-map ROI.  
% 
%    1. Select ROI in the Flat window.
% 
%    2. Use the Area Measure pull down in the Analysis pulldown of
% the Flat window.  
% 
% NOTE: this code must find the flat.mat file associated with the
% unfold, load it, and find the 'unfoldMeshSummary' field. This extra
% information is saved from within newer versions of mrFlatMesh when
% you check 'save extra info'.
%
% The method here is much preferred to that in measureFlatROIArea, which
% tries to create it's own triangulation based only on layer 1 nodes. This
% usually works OK for ROIs that are convex, but can severely over-estimate
% the area when the ROI has concavities. Here we just use the triangles
% from the gray/white interface surface mesh.
% 
% See Also: measureFlatROIArea, sumTriangularArea 
%
% HISTORY:
% 2003.01.07 RFD (bob@white.stanford.edu) wrote it.
% 2003.01.30 RFD: minor cleaning, tested some alternative vertex inclusion
% criteria.
% 2006.04.10 RFD: addes comments about our preference for this function
% over the older measureFlatROIArea.

global mrSESSION;

if(~exist('grayThickness','var') | isempty(grayThickness))
    grayThickness = 3;
end

% If someone want the area returned, then we assume that we are scripted
% and thus don't use gui stuff.
if(nargout<2),  gui = 1;
else,  gui = 0; end

% Get selpts from current ROI
if view.selectedROI,   ROIcoords = getCurROIcoords(view);
else  error('No current ROI'); end
ROIname = view.ROIs(view.selectedROI).name;

if isempty(ROIcoords), error('ROI is empty!'); end

hemi = ROIcoords(3,1);
if(~all(ROIcoords(3,:) == hemi))
    error('ROI spans both hemispheres!');
end

% load the flat.mat file
if(hemi==1)
    hemiName = 'left';
    unfoldFile = view.leftPath;
else
    hemiName  = 'right';
    unfoldFile = view.rightPath;
end
if(~exist(unfoldFile,'file'))
    % Try to fix broken paths
    warning([unfoldFile ' not found- trying to find it...']);
    anatPath = getAnatomyPath(mrSESSION.subject);
    indx = findstr(mrSESSION.subject,unfoldFile);
    if(~isempty(indx))
        unfoldFile = fullfile(fileparts(anatPath), unfoldFile(indx(1):end));
        unfoldFile = strrep(unfoldFile, '\', filesep);
        unfoldFile = strrep(unfoldFile, '/', filesep);
    end
    if(exist(unfoldFile,'file'))
        warning(['Using a similarly-named file (' unfoldFile ')...']);
    else
        disp(unfoldFile);
        [f,p] = myUiGetFile(anatPath, {'*.mat';'*.*'}, ['Select ' hemiName ' unfold file...']);
        unfoldFile = fullfile(p,f);
    end
end

if(~isfield(view,'mesh') | size(view.mesh) < hemi | isempty(view.mesh{hemi}))
    unfold = load(unfoldFile);
    disp(['loaded unfold from ', unfoldFile,'...']);
    if(~isfield(unfold,'unfoldMeshSummary'))
        disp('*************************************************************');
        disp('This flat.mat file does not have an unfoldMeshSummary field!');
        disp('Redo the unfold and tell mrFlatMesh to save the extra info.');
        disp('For now, you can get an area estimate from measureFlatROIArea.');
        error('Missing the unfoldMeshSummary field.');
    end
    view.mesh{hemi} = unfold.unfoldMeshSummary;
end

locs2d = view.mesh{hemi}.locs2d;

% To convert raw glocs2d values to those used in mrLoadRet, we do:
minLocs2d = min(locs2d);
locs2d(:,1) = locs2d(:,1) - minLocs2d(1) + 1;
locs2d(:,2) = locs2d(:,2) - minLocs2d(2) + 1;
locs2d = locs2d'; 

scaledVertices(:,1) = view.mesh{hemi}.uniqueVertices(:,1) .* view.mesh{hemi}.scaleFactor(1);
scaledVertices(:,2) = view.mesh{hemi}.uniqueVertices(:,2) .* view.mesh{hemi}.scaleFactor(2);
scaledVertices(:,3) = view.mesh{hemi}.uniqueVertices(:,3) .* view.mesh{hemi}.scaleFactor(3);
areaList3d = findFaceArea(view.mesh{hemi}.connectionMatrix, ...
    scaledVertices, ...
    view.mesh{hemi}.uniqueFaceIndexList);
% Lets also measure the 2d area, just for fun.
areaList2d = findFaceArea(view.mesh{hemi}.connectionMatrix, ...
    [locs2d',zeros(size(locs2d,2),1)], ...
    view.mesh{hemi}.uniqueFaceIndexList);

%
% Find the triangles that overlap with the ROI.
%

% First we find all the vertices that fall within the ROI. 
%
% Intersect returns only the unique matches, but we want them all.
% So, we use ismember, which tells us for each row of the first matrix if
% it matches any row in the second matrix.
roiVertexIndices = find(ismember(round(locs2d)', ROIcoords(1:2,:)', 'rows'));

% Now we find the triangles (faces) within the ROI by a simple heuristic-
% any one of the triangle's vertices is in the ROI. What we should really 
% do is select only those triangles whose AREA falls mostly within the ROI. 
% But that's too hard (ie. would be slow in matlab).
roiFaceIndices = find(ismember(view.mesh{hemi}.uniqueFaceIndexList(:,1), roiVertexIndices) ...
    | ismember(view.mesh{hemi}.uniqueFaceIndexList(:,2), roiVertexIndices) ...
    | ismember(view.mesh{hemi}.uniqueFaceIndexList(:,3), roiVertexIndices));
% 2003.01.30 RFD: NOTE: I tried making the above inclusion criteria more 
% conservative- so that two of it's vertices needed to be within the ROI. 
% However, this wasn't much better, especially for thin ROIs, since it
% erred in the other direction and eliminated too many triangles.
% But that more conservative criteria would have the very desireable 
% property that any triangle will only get included in one of
% two abutting ROIs, never in both like the old method sometimes did.
% vertOne = ismember(view.mesh{hemi}.uniqueFaceIndexList(:,1), RoiVertexIndices);
% vertTwo = ismember(view.mesh{hemi}.uniqueFaceIndexList(:,2), RoiVertexIndices);
% vertThree = ismember(view.mesh{hemi}.uniqueFaceIndexList(:,3), RoiVertexIndices);
% roiFaceIndices = find((vertOne & vertTwo) | (vertOne & vertThree) | (vertTwo & vertThree));

area3d = sum(areaList3d(roiFaceIndices));
area2d = sum(areaList2d(roiFaceIndices));

areaStr = addText([],sprintf('%s area = %.0f mm^2 (%d triangles)\n',ROIname,area3d,length(roiFaceIndices)));
areaStr = addText(areaStr,sprintf('2d = %.0f~mm^2 and %.0f voxels',area2d,size(ROIcoords,2)));

if(gui)
    %msgbox([areaStr],[ROIname ' area']);
    % Make the ROI coords point to the upper left of each ROI pixel
    ROIcoords = ROIcoords-0.5;
    % now define four the lines for each ROI coordinate.
    roiLinesX = [[ ROIcoords(2,:);   ROIcoords(2,:)+1 ],...
            [ ROIcoords(2,:);   ROIcoords(2,:)   ],...
            [ ROIcoords(2,:)+1; ROIcoords(2,:)+1 ],...
            [ ROIcoords(2,:)+1; ROIcoords(2,:)   ]];
    roiLinesY =-[[ ROIcoords(1,:);   ROIcoords(1,:)   ],...
            [ ROIcoords(1,:);   ROIcoords(1,:)+1 ],...
            [ ROIcoords(1,:)+1; ROIcoords(1,:)   ],...
            [ ROIcoords(1,:)+1; ROIcoords(1,:)+1 ]];
    
    roiFaces = view.mesh{hemi}.uniqueFaceIndexList(roiFaceIndices,:);
    % This will color each triangle with the z-depth of the surface
    % (something like curvature).
    %colors = scaledVertices(roiFaces(:,1),3) + scaledVertices(roiFaces(:,2),3) + scaledVertices(roiFaces(:,3),3);
    %colors = colors-mean(colors);
    % Use abs to cope with the fact that we sometimes get negative numbers here...
    colors = abs(log(areaList3d(roiFaceIndices)./areaList2d(roiFaceIndices)));
    %areaStr = [areaStr ' (Color shows log 3D/2D area)'];
    
    figure;  hold on; axis equal; colormap(hot);
    patch([locs2d(2,roiFaces(:,1));...
            locs2d(2,roiFaces(:,2));...
            locs2d(2,roiFaces(:,3))], ...
        -[locs2d(1,roiFaces(:,1));...
            locs2d(1,roiFaces(:,2));...
            locs2d(1,roiFaces(:,3))], colors');
    lineH = line(roiLinesX, roiLinesY,'Color','blue');
    colorbar;
    %plot(locs2d(2,roiVertexIndices), -locs2d(1,roiVertexIndices), '.r');
    %plot(round(locs2d(2,roiVertexIndices)), -round(locs2dInt(1,roiVertexIndices)), '.g');
    hold off;
    title(areaStr);
end

return;
