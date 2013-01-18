function [view,curvature] = measureFlatROICurvature(view)
%
% [view,curvature] = measureFlatROICurvature(view)
%
% Extracts the curvature of the current flat-map ROI.  
% 
% 
% NOTE: this code must find the flat.mat file associated with the
% unfold, load it, and find the 'unfoldMeshSummary' field. This extra
% information is saved from within newer versions of mrFlatMesh when
% you check 'save extra info'.
% 
% See Also: measureFlatROIAreaMesh, sumTriangularArea 
%
% HISTORY:
% 2003.05.21 RFD (bob@white.stanford.edu) wrote it.


% If someone wants all the curvature values returned, then we assume 
% that we are scripted and thus don't use gui stuff.
if(nargout<2)
    gui = 1;
else
    gui = 0;
end

% Get selpts from current ROI
if view.selectedROI
  ROIcoords = getCurROIcoords(view);
else
  error('No current ROI');
end
ROIname = view.ROIs(view.selectedROI).name;

if isempty(ROIcoords)
  error('ROI is empty!');
end

hemi = ROIcoords(3,1);
if(~all(ROIcoords(3,:) == hemi))
  error('ROI spans both hemispheres!');
end

% load the flat.mat file
if(hemi==1)
    unfoldFile = view.leftPath;
else
    unfoldFile = view.rightPath;
end
if(~isfield(view,'mesh') | isempty(view.mesh{hemi}))
    unfold = load(unfoldFile);
    disp(['loaded unfold from ', unfoldFile,'...']);
    if(~isfield(unfold,'unfoldMeshSummary'))
        disp('*************************************************************');
        disp('This flat.mat file does not have an unfoldMeshSummary field!');
        disp('Redo the unfold- try: ');
        disp(['  mrFlatMeshRebuildUnfold(''',unfoldFile,''')']);
        disp('Be sure to tell mrFlatMesh to save the extra info.');
        disp('In the mean time, you can get an area estimate from measureFlatROIArea.');
        error('Sorry- but I can''t go on without the unfoldMeshSummary field.');
    end
    view.mesh{hemi} = unfold.unfoldMeshSummary;
%     view.mesh{hemi}.curvature = unfold.curvature;
%     view.mesh{hemi}.gLocs2d = unfold.gLocs2d;
%     view.mesh{hemi}.gLocs3d = unfold.gLocs3d;
else
    disp('Using cached mesh info from view struct.');
end

% To convert raw glocs2d values to those used in mrLoadRet, we do:
locs2d = view.mesh{hemi}.locs2d;
minLocs2d = min(locs2d);
locs2d(:,1) = locs2d(:,1) - minLocs2d(1) + 1;
locs2d(:,2) = locs2d(:,2) - minLocs2d(2) + 1;
locs2d = locs2d'; 

%
% Find the triangles that overlap with the ROI.
%
                      
% We find all the vertices that fall within the ROI. 
%
% Intersect returns only the unique matches, but we want them all.
% So, we use ismember, which tells us for each row of the first matrix if
% it matches any row in the second matrix.
roiVertexIndices = find(ismember(round(locs2d)', ROIcoords(1:2,:)', 'rows'));

curvature = view.mesh{hemi}.curvature(roiVertexIndices);
% curvature should be on the interval -1 to 1. Zero should mean true zero curvature,
% but we aren't sure what the extremes mean, since we don't know mrGray's
% scaling rules.
meanCurvature = mean(curvature);

curStr = [ROIname ' mean curvature = ' num2str(meanCurvature)];
disp(curStr);
if(gui)
    %msgbox([areaStr],[ROIname ' area']);
    % Make the ROI coords point to the upper left of each ROI pixel
%     ROIcoords = ROIcoords-0.5;
%     % now define four the lines for each ROI coordinate.
%     roiLinesX = [[ ROIcoords(2,:);   ROIcoords(2,:)+1 ],...
%                  [ ROIcoords(2,:);   ROIcoords(2,:)   ],...
%                  [ ROIcoords(2,:)+1; ROIcoords(2,:)+1 ],...
%                  [ ROIcoords(2,:)+1; ROIcoords(2,:)   ]];
%     roiLinesY =-[[ ROIcoords(1,:);   ROIcoords(1,:)   ],...
%                  [ ROIcoords(1,:);   ROIcoords(1,:)+1 ],...
%                  [ ROIcoords(1,:)+1; ROIcoords(1,:)   ],...
%                  [ ROIcoords(1,:)+1; ROIcoords(1,:)+1 ]];
% 
%     roiFaces = view.mesh(hemi).uniqueFaceIndexList(roiFaceIndices,:);
    
    figure;
%     axis equal;
%     colormap(hot);
%     colors = curvature/2+1;
%     pcolor(locs2d(2,roiVertexIndices), -locs2d(1,roiVertexIndices), colors');
%     colorbar;
    hist(curvature, ceil(length(curvature)/10));
    ax = axis;
    axis([-1,1,ax(3),ax(4)]);
    title(curStr);
end

return;
