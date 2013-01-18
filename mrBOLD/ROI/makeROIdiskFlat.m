function flat = makeROIdisk(flat,radius,name,select,color)
%
% function flat = makeROIdisk(flat,[radius],[name],[select],[color])
%
% AUTHOR:  Wandell
% DATE:    08.08.00
% PURPOSE:
%  Select a point in the flat window, and then create an ROI of those
%  points within a distance radius from the selected point.   The routine
%  converts the selected point into the GRAY view,and then uses
%  volume.nodes and volume.edges to floodfill out to the nearby points.
%
% djh, 2/9/2001
%    replaced globals FLAT & VOLUME with local variables.
% 7/16/02 djh, replaced mrSESSION.vAnatomyPath with global vANATOMYPATH

global vANATOMYPATH;
mmPerPix = readVolAnatHeader(vANATOMYPATH);

% Check some flat and volume stuff here when you
% get a chance to fix this code up

% Get a gray structure because we need the gray nodes.
gray=getSelectedGray;
if isempty(gray), gray=initHiddenGray; end

% Fill radius variable
if ~exist('radius','var') | isempty(radius)
   prompt={'Radius (mm)'};
   def={'3'};
   lineNo=[1 10];
   dlgTitle = 'add disk ROI';
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   if isempty(answer)
      myErrorDlg('Canceling addROIdisk');
   else
      radius = str2num(answer{1});
   end
end
fprintf('radius = %.0f\n',radius);

if ~exist('name','var'), name=sprintf('disk%.0f',radius); end
if ~exist('select','var'), select=1; end
if ~exist('color','var'), color='b'; end

% Select flat figure and get a single point from the user
figure(flat.ui.figNum)
rgn = round(ginput(1));


% Note: ginput hands them back in x, y order (1st col is x and
% 2nd col is y).  But we use them in the opposite order (row,col), so that % we want (y,x).  So we flip 'em.
rgn = fliplr(rgn);

% left or right?
slice = viewGet(flat, 'Current Slice');
% Convert coords to canonical frame of reference
% Do an (inverse) rotation if necessary
if (strcmp(flat.viewType,'Flat'))
    rgn=(rotateCoords(flat,rgn',1));
end
% % If we have asked for a flat map rotation, we need to map the coordinate
% % given back to the unrotated version.
% 
%   if (isfield(view,'rotateImageDegrees'))
%         if(view.rotateImageDegrees(slice))
%         midPoint=view.ui.imSize/2;
%         
%         % To rotate the coordinates correctly, we need to zero-center the
%         % coords.
%         rot_rgn=rgn(:)-midPoint(:);
%         
%         % Make the transform matrix
%         angRad=-view.rotateImageDegrees*pi/180;
%     
%         rotMat=[cos(angRad) -sin(angRad);sin(angRad) cos(angRad)];
%         
%         rot_rgn=rot_rgn'*rotMat;
%         rgn=rot_rgn(:)+mpOffset(:);
%     
%       end
%     end
%     


% get nearest gray node (note that not all points on the flat map correspond to
% gray nodes)
flatDistances = (flat.coords{slice}(1,:)-rgn(1)).^2 + (flat.coords{slice}(2,:)-rgn(2)).^2;

[val,index] = min(flatDistances);
if val > 3, warndlg('No gray nodes within 3mm.  Click again.'); return; end

% Find start point in the grayNodes
startPtGrayCoord = flat.grayCoords{slice}(:,index);
if (slice==1)
    nodes = gray.allLeftNodes;
    edges = gray.allLeftEdges;
else
    nodes = gray.allRightNodes;
    edges = gray.allRightEdges;
end

startNode = ...
    find(nodes(2,:) == startPtGrayCoord(1) & ...
    nodes(1,:) == startPtGrayCoord(2) & ...
    nodes(3,:) == startPtGrayCoord(3));

% We don't understand why startNode is empty sometimes.
if isempty(startNode), errordlg('Clicking another node.'); return; end

% Compute distances
distances = mrManDist(nodes,edges,startNode,mmPerPix,-1,radius);
diskIndices = find(distances >= 0);

% Coords in the gray matter
grayCoords = nodes([2 1 3],diskIndices);

% Make temporary grayROI
grayROI.coords = grayCoords;
grayROI.name = name;
grayROI.color = color;
grayROI.viewType = 'Gray';
[gray,pos] = addROI(gray,grayROI,0);

% Transform to flat
flatROI = vol2flatROI(grayROI,gray,flat);
flat = addROI(flat,flatROI,select);

% Delete temporary grayROI
gray = deleteROI(gray,pos);

return;
