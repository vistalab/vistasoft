function rxDrawRx(rx,Z,ori);
%
% rxDrawRx(rx,Z,[ori]);
%
% Draw lines for a prescription on top
% of a volume slice image. Z is the
% target slice in the non-xformed volume.
%
% ori is a flag to account for viewing
% the prescription on different orientations
% of the volume. Values are 1 -- axial,
% 2 -- coronal, 3 -- sagittal, 4 -- orthogonal.
% Default is 3.
%
% ras 02/05.
if ieNotDefined('ori')
    ori = 3;
end

rxSlice = get(rx.ui.rxSlice.sliderHandle,'Value');
volSlice = get(rx.ui.volSlice.sliderHandle,'Value');

xsz = rx.rxDims(1);
ysz = rx.rxDims(2);
zsz = rx.rxDims(3);
nSlices = zsz;

% build up coords for corners of each slice
% (also at this step, cols/rows -> x/y)
[X Y Z] = meshgrid([1 ysz],[1 xsz],[1:zsz]); 
corners = [X(:) Y(:) Z(:) ones(size(Z(:)))]';

% get new coords for the interp slice
newCorners = rx.xform * corners;
   
% account for view direction --
% if view is not sagittal, the volume has
% been permuted. Make a parallel
% permutation of the corner coordinates.
% (Note that b/c these coords are in x/y/z, rather
% than rows/cols/slices, the permutation order
% is slightly different):
if ori ~= 3 % in sagittal/ori=3 case, do nothing
    % first check if we're using radiological conventions
    hRadiological = findobj('Tag','rxRadiologicalMenu');
    if isequal(get(hRadiological, 'Checked'), 'on')
        newCorners(3,:) = rx.volDims(3) - newCorners(3,:);
    end
    
    if ori==1, newCorners = newCorners([3 1 2 4],:);  end  % axi
	if ori==2, newCorners = newCorners([3 2 1 4],:);  end  % cor    
end


% loop through and draw slices
hold on
for slice = 1:nSlices
    % find range of columns pertaining to this
    % slice in the newCorners matrix:
    rng = [1:4] + (slice-1)*4;
    
    % grab new coords of each corner point:
    ulhc = newCorners(1:3,rng(1)); % upper left-hand corner, etc
    urhc = newCorners(1:3,rng(2)); % upper right-hand corner
    llhc = newCorners(1:3,rng(3)); % lower left-hand corner
    lrhc = newCorners(1:3,rng(4)); % lower right-hand corner
    
    % for each slice, there are two pairs of 
    % edges we want to check: the top/bottom
    % of each slice, and the left/right edges of
    % each slice.
    % only want to draw one set of edges, so decide now:
    topEdge = ulhc-urhc;
    rightEdge = ulhc-llhc;
    if abs(topEdge(3))<0.5 & abs(rightEdge(3))<0.5
        % no significant change for either edge,
        % don't draw either
        return
    elseif abs(topEdge(3)) > abs(rightEdge(3))
        edge = [ulhc urhc llhc lrhc];
		cmap = winter( ceil(nSlices*3/2) ); 
    else
        edge = [ulhc llhc urhc lrhc];
		cmap = autumn( ceil(nSlices*3/2) );      
    end
    
    % compute the X, Y coords where the top
    % and bottom rows of the slice cross the
    % plane of the non-xformed volume slice:
    [xpos(1) ypos(1)] = intercept(edge(:,1),edge(:,2),volSlice);
    [xpos(2) ypos(2)] = intercept(edge(:,3),edge(:,4),volSlice);
    
    % mark a line for this slice
    if slice==rxSlice
        line(xpos, ypos, 'Color', 'y');
    else
        line(xpos, ypos, 'Color', cmap(slice,:));
    end
    
%     % mark a green dot for the top of the slice,
%     % and a red dot for the bottom of the slice
%     plot(xpos(1),ypos(1),'g.');
%     plot(xpos(2),ypos(2),'r.');
end

return
% /---------------------------------------------/ %




% /---------------------------------------------/ %
function [x, y] = intercept(pt1,pt2,z);
% Calculate the x, y coords where a line
% passing through 3D points pt1 and pt2
% also passes through the plane defined
% by Z==z. If it never passes through,
% return empty vectors.
x = [];
y = [];

dx = pt2(1)-pt1(1);
dy = pt2(2)-pt1(2);
dz = pt2(3)-pt1(3);

% check: does it pass through the
% plane at all?
if dz==0
    % nope; return empty vectors
    return
end

% slopes of change w.r.t. z
dxdz = dx/dz;
dydz = dy/dz;

% compute intercept points
x = pt1(1) + dxdz*(z-pt1(3));
y = pt1(2) + dydz*(z-pt1(3));

return
