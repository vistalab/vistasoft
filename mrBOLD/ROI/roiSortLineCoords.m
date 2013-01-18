function [roi] = roiSortLineCoords(view, roi, show_res)
% Arrange the coordinates in a gray matter line ROI so that they progress
% along the line.
%
%  [roi sampleNodes distNodes]  = roiSortLineCoords(view, roi);
%
%
% ras, 12/2008.  Adapted from code in plotLineROI.
% SD, 02/2011. This nor original plotLineROI was not working properly,
%              rewritten sorting algorithm version.

if notDefined('view'),	view = getSelectedGray;		end
if notDefined('roi'),	roi = view.ROIs(view.selectedROI);		end
if notDefined('show_res'), show_res = true; end

% TODO: add a mex-file test of mrManDist here. This MEX file is needed for
% this function to work...
% ...

% get dimensions
mmPerPix = view.mmPerVox;

% get all gray coords, nodes and edges
nodes   = double(view.nodes);
edges   = double(view.edges);
coords  = double(view.coords);
%numNeighbors = double(view.nodes(4,:));
%edgeOffsets  = double(view.nodes(5,:));

% Get nearest gray node
allNodeIndices = zeros(1,size(roi.coords,2));
for ii=1:size(roi.coords,2)
    grayNode = find(nodes(2,:) == roi.coords(1,ii) & ...
                    nodes(1,:) == roi.coords(2,ii) & ...
                    nodes(3,:) == roi.coords(3,ii));
   
    % Catch errors. 
    if(isempty(grayNode))
        error('No gray nodes were found!');
    end
    if(length(grayNode)>1)
        fprintf('[%s]: WARNING- coord %d - more than one grayNode found!\n',mfilename,ii);
        grayNode = grayNode(1);
    end
    allNodeIndices(ii) = grayNode;
end

% full connection matrix
fullConMat = dhkGrayConMat(nodes, edges, coords);

% limit connnection matrix to roi indices
conMat = fullConMat(allNodeIndices,allNodeIndices);

% eliminate zeros from connection matrix
conMat = full(conMat);
conMat(conMat==0)=inf;

% problem with limited connection matrix: sometimes not all points are
% connected introducing a 'break' -we need to fill up the gaps
allpaths=shortpath(conMat,1,[]); % if tmp contains inf: break exists
while any(isinf(allpaths))
    d = inf; s = 0; t = 0;
    for n=1:numel(allNodeIndices)
        tmppaths=shortpath(conMat,n,[]);
        unconnected = isinf(tmppaths);
        tmp = mrManDist(nodes,edges,allNodeIndices(n),mmPerPix,999);
        [tmp_d tmp_ii] = min(tmp(allNodeIndices(unconnected)));
        % keep shortest path through fully connected matrix
        if ~isempty(tmp_d) && tmp_d<d
            d=tmp_d;
            s=n;
            % find end node
            alln = false(size(allNodeIndices));
            unc = false(size(allNodeIndices(unconnected)));
            unc(tmp_ii) = true;
            alln(unconnected) = unc;
            t=find(alln);
        end
    end
    
    
    % get path indices
    [junk,p]=shortpath(fullConMat,allNodeIndices(s),allNodeIndices(t));
    
    % get unique indices
    [junk ib] = intersect(p,allNodeIndices);
    d=true(size(p));d(ib)=0;
    
    % grow nodes
    allNodeIndices = [allNodeIndices, p(d)];
    conMat = fullConMat(allNodeIndices,allNodeIndices);
    conMat = full(conMat);
    conMat(conMat==0)=inf;

    % recheck
    allpaths=shortpath(conMat,1,[]);
end

% get longest path, this is the most direct path from the beginning to the
% end of the line-roi. But it does not pass through all points.
d = 0; s = 0; t = 0;
for n=1:numel(allNodeIndices)
    tmp=shortpath(conMat,n,[]);
    tmp(isinf(tmp))=0;
    [tmp_d,ii]=max(tmp);
    % keep longest real path
    if tmp_d>d
        d=tmp_d;
        s=n;
        t=ii;
    end
end

% get path indices 
[d,p]=shortpath(conMat,s,t);
newcoords = coords(:,allNodeIndices(p));


% plot results
if show_res
    figure;
    xyz = roi.coords';
    plot3(xyz(:,1),xyz(:,2),xyz(:,3),'k.');hold on
    xyz = coords(:,allNodeIndices(p))';
    plot3(xyz(:,1),xyz(:,2),xyz(:,3),'ro-');
end

% sort the ROI coords
roi.name = [roi.name ' (Line Sorted)'];
roi.coords = newcoords;

return

    

