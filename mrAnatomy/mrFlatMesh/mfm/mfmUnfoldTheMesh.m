function [unfoldMesh, maps, unfolded2D] = mfmUnfoldTheMesh(unfoldMesh, params, nFaces)
%
%  [unfoldMesh, maps] = mfmUnfoldTheMesh(unfoldMesh, params, nFaces)
%
% Author: Winawer
% Purpose:
%   Unfold the unfoldMesh.  This is the key mathematical step in the
%   flattening process.
%  
%   Sub-routine derived from Alex's unfoldMeshFromGUI code.
%
% See Also:  unfoldMeshFromGUI

% Get all the variables we may need
meshFileName     = params.meshFileName;
grayFileName     = params.grayFileName;
flatFileName     = params.flatFileName;
startCoords      = params.startCoords;
scaleFactor      = params.scaleFactor;
perimDist        = params.perimDist;
statusHandle     = params.statusHandle;
busyHandle       = params.busyHandle;
spacingMethod    = params.spacingMethod;
adjustSpacing    = params.adjustSpacing;
gridSpacing      = params.gridSpacing;
showFigures      = params.showFigures;
saveExtra        = params.saveExtra;
truePerimDist    = params.truePerimDist;
hemi             = params.hemi;
nperims          = params.NPERIMS;
saveIntermeidate = params.SAVE_INTERMEDIATE;
numberOfSteps    = params.NUMBEROFSTEPS;


% Find the N and P connection matrices
statusStringAdd(statusHandle,'Finding sub-mesh connection matrix.');
[N, P, unfoldMesh.internalNodes] = findNPConnection(unfoldMesh);

% Here we find the squared 3D distance from each point to its neighbours.
[unfoldMesh.distSQ]=find3DNeighbourDists(unfoldMesh,scaleFactor);   

fullConMatScaled=scaleConnectionMatrixToDist(sqrt(unfoldMesh.distSQ));

% Now split the full conMat up until N and P
N = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.internalNodes);
P = fullConMatScaled(unfoldMesh.internalNodes,unfoldMesh.orderedUniquePerimeterPoints);

% Assign the initial perimeter points - they're going to go in a circle for now...
numPerimPoints=length(unfoldMesh.orderedUniquePerimeterPoints);

statusStringAdd(statusHandle,'Assigning perimeter points');

% Can set distances around circle to match actual distances from the center. 
unfoldMesh.X_zero = assignPerimeterPositions(perimDist,unfoldMesh); 


% THIS IS WHERE WE SOLVE THE POSITION EQUATION - THIS EQUATION IS THE HEART OF THE ROUTINE!
statusStringAdd(statusHandle, 'Solving position equation.');
X =(speye(size(N)) - N) \ (sparse(P * unfoldMesh.X_zero));

% Remember what these variables are: 
% X: 2d locations of internal points
% X_zero : 2d locations of perimeter
% N sparse connection matrix for internal points
% P sparse connection matrix between perimeter and internal points
% (Note - the connection matrix between the perimeter points is implicit in
% their order - they are connected in a ring)
% The 3D coordinates o

unfoldMesh.N=N;
unfoldMesh.P=P;
unfoldMesh.X=X;

% Find the face areas for the unfolded and folded versions of the unfoldMesh
% This is a good error metric. We'll save this out with the flat.mat file.
% (ARW)
%
% Do this by calling findFaceArea. We call it twice, once with the 3D vertices and once with 
% a pseudo-3D vertex set with the 3rd dimension set to 0
% The areaList3D and errorList are saved out,
% but I don't know where they are used.  Perhaps Bob? (BW)

statusStringAdd(statusHandle,['Calculating face area distortions']);

% This seems like an important piece of code, the ordering used to define
% unfolded2D is complicated.  We need comments and it would be better to
% have it in a function.
unfolded3D = unfoldMesh.uniqueVertices;
indices2D  = unfoldMesh.internalNodes;
unfolded2D(indices2D,1:2) = full(unfoldMesh.X);
indices2D  = unfoldMesh.orderedUniquePerimeterPoints;
unfolded2D(indices2D,1:2) = full(unfoldMesh.X_zero);
unfolded2D(:,3) = 0;

% Is this related to RFD stuff?
try
    maps.areaList3D = findFaceArea(unfoldMesh.connectionMatrix,unfolded3D,unfoldMesh.uniqueFaceIndexList);
    maps.areaList2D = findFaceArea(unfoldMesh.connectionMatrix,unfolded2D,unfoldMesh.uniqueFaceIndexList);
    
    % Hmm.  We get a divide by zero somtimes, indicating that the 2D area is
    % zero.  That can't be good.  I protected this by adding eps.  But that is
    % just to spare the user.
    maps.errorList = maps.areaList3D./(maps.areaList2D + eps);
    maps.zeroAreaList = find(maps.areaList2D == 0);
    if ~isempty(maps.zeroAreaList), fprintf('Zero 2D area (nodes): %.0f\n',maps.zeroAreaList); end

catch
    maps.areaList2D = [];
    maps.areaList3D = [];
    maps.errorList = [];
    maps.zeroAreaList = [];
    
    disp('Failed to compute face areas. Won''t be able to show the results figures.')
    disp(lasterr);
    showFigures = false;
    
end
    
    

% In order to plot this as a nice picture, we want to find the (x,y) center
% of mass of each 2D face.  
% I think cogs means center-of-gravity (BW).  I am not sure we use this
% any more, and I am not sure we use the areaList stuff above, either.
 if (showFigures)
    [maps.areaErrorMap, maps.meanX, maps.meanY] = ...
        mfmAreaErrorMap(unfoldMesh, nFaces, unfolded2D,maps.errorList);
 end

return