function startNode=locateStartNode(mesh)
% Waits for a single click within the figure window and 
% Calculates the node that this corresponds to.
% 1) The click represents the intersection of the screen and a line (L) normal to the screen
% 2) By using the CurrentPosition property of the axes, you get the 3D coordinates of
%  the intersection of this line with the front and back of the axes
% 3) Want to find the intersection of this line with a single face ->
% 3.1) Have to solve some equations but first, we can eliminate lots of patches by 
%     doing a dot product of the vector L and the VertexNormals of the rendered object.
% Anything with a dot prod >0 is facing away from the viewer and the faces containing that 
% vertex can be ignored.
% 3.2) Then solve for interesctions of line (L) and all the planes defined by the remaining faces
% 3.3) Then do a bounding box check on each point/triangle pair to eliminate points that 
%      lie very far from the corresponding triangles. The list of remaining point/tri pairs
%      will be very small. 
% 3.4) Solve sim lin eq. (many ways to do this) to see if line/tri interect. There should
% be just one case where this happens.
% 3.5) And then find which of the 3 triangle vertices lies closest to this point.
% 3.6) On rare occasions, there may be two or more faces identified by this procedure. In this case
% take the final vertex closest to the front interesect point.

% Find min and max of the mesh bounds for checking later
xyzMin=min(mesh.uniqueVertices);
xyzMax=max(mesh.uniqueVertices);

a=ginput(1);
twoPointsInL=get(gca,'CurrentPoint')
vectorL=(twoPointsInL(1,:)-twoPointsInL(2,:));
pointL=twoPointsInL(1,:);

otherNormals=mesh.normal(mesh.vertsToUnique,:);

% Find vertices that have a normal pointing towards us. What is a vertex normal anyway?
%goodVertices=find((otherNormals*vectorL')>0);
%badVertices=setdiff((1:length(mesh.uniqueVertices)),goodVectors)';
goodVertices=1:length(mesh.uniqueVertices);


%mesh.uniqueCols(goodVertices,:)=repmat([0 128 0 255],length(goodVertices),1);
%mesh.uniqueCols(badVertices,:)=repmat([128 0 0 255],length(badVertices),1);

%oldView=get(gca,'View');

%close(6);
%figure(6);
%delete (mesh.objectHandle);
%refresh(6);

%mesh.objectHandle=showPatch2(mesh);
%set(gca,'View',oldView);

% Have identified good vertices. Now make a list of good faces - faces that contain 3 good vertices
ufi1=mesh.uniqueFaceIndexList(:,1);
is_ufi=ismember(ufi1,goodVertices);
ufi2=mesh.uniqueFaceIndexList(:,2);
is_ufi=(is_ufi==ismember(ufi2,goodVertices));
ufi3=mesh.uniqueFaceIndexList(:,3);
is_ufi=(is_ufi==ismember(ufi3,goodVertices));

goodFaces=find(is_ufi); % goodFaces is a list of faces that we'll consider becasue they're pointing towards us. It's a set of indices into mesh.uniqueFaceIndexList

% Now do solves for line and plane. Line defined by a point pointL and a vector vectorL
% Think we have to do this in a loop but it's easy to code in C later...

% Initialize the arrays to hold intersect positions for each face in goodFaces
faceIntersects=zeros(length(goodFaces),3);
pointCheckFlag=zeros(length(goodFaces),1);
% These are used for bounds checking
lowerThan=zeros(3,3);
greaterThan=zeros(3,3);


tic
% Do this solve using determinant solution from Eric Weisstein's World of Mathematics :)
for t=1:length(goodFaces)
   pointIndex=mesh.uniqueFaceIndexList(goodFaces(t),:);
   
   % Points in single triangle are held in pointLocations
   pointLocations=mesh.uniqueVertices([pointIndex(1) pointIndex(2) pointIndex(3)],:);
   
   % top part of division
  topMat=[pointLocations',twoPointsInL(1,:)'];
  topMat=[1 1 1 1;topMat];
  det_topMat=det(topMat);
  
  % Bottom part
  bottomMat=[pointLocations',(twoPointsInL(2,:)-twoPointsInL(1,:))'];
  bottomMat=[1 1 1 0;bottomMat];
  
  det_bottomMat=det(bottomMat);
  if (det_bottomMat)
     det_ratio=det_topMat/det_bottomMat;
     faceIntersects(t,:)=vectorL*det_ratio+twoPointsInL(1,:);
     
     % Have the intersect point. Since we're here we might as well do some bounds checking
     lowerThan(:,1)=faceIntersects(t,1)<pointLocations(:,1);
     greaterThan(:,1)=faceIntersects(t,1)>pointLocations(:,1);
     lowerThan(:,2)=faceIntersects(t,2)<pointLocations(:,2);
     greaterThan(:,2)=faceIntersects(t,2)>pointLocations(:,2);
     lowerThan(:,3)=faceIntersects(t,3)<pointLocations(:,3);
     greaterThan(:,3)=faceIntersects(t,3)>pointLocations(:,3); 
     
     pointCheckFlag(t)=(sum(sum(lowerThan)==3) + sum(sum(greaterThan)==3));
     
     
     
  else
     
     faceIntersects(t,:)=[NaN NaN NaN];
     pointCheckFlag(t)=1;
     
  end
  
end
toc

% Okay - so for every face indexed in goodFaces, we have a plane intersection (NOT a triangle intersection - that remains to be checked!)
% We know that if pointCheckFlag==1 or the face intersect is a Nan then it's not a triangle intersection
% Make a list of all the remaining potentially good triangles

goodList=find(pointCheckFlag==0);

facesRemaining=goodFaces(goodList)
intersectsRemaining=faceIntersects(goodList,:)
pointsRemaining=mesh.uniqueFaceIndexList(goodList,:)

numPointsRemaining=length(goodList)
   
% Does the line pass through these triangles?


%delete (mesh.objectHandle);


triangleIntersects=[];
goodPointIndices=[];
triangleIntersectionsFound=0;


% Use property that for an internal point P, and triangle points T1, T2, T3
% There are 3 vectors PT1, PT2 and PT3. The sum of the angles between these vectors
% =2*pi for an internal point only.

for t=1:numPointsRemaining
   
   pointIndex=pointsRemaining(t,:);
   pointLocations=mesh.uniqueVertices([pointIndex(1) pointIndex(2) pointIndex(3)],:);
   thisIntersect=intersectsRemaining(t,:);
   
   % Find normalized 
   Pvects=(pointLocations-repmat(thisIntersect,3,1))';
   powPvects=sqrt(sum(Pvects.^2));
   Pvects=Pvects./repmat(powPvects,3,1);
   
   % Find angles using dot prod.
   
   sumAngle=acos(sum(Pvects(:,1).*Pvects(:,2)))+...
      acos(sum(Pvects(:,2).*Pvects(:,3)))+...
      acos(sum(Pvects(:,3).*Pvects(:,1)))
  
 
   if (round(sumAngle*10)==round(20*pi))
      % We've got a live one
      triangleIntersects=[triangleIntersects;thisIntersect];
      goodPointIndices=[goodPointIndices;pointIndex];
      triangleIntersectionsFound=triangleIntersectionsFound+1;
      
   end
end



% Internal angles should sum to pi*2

   
   % Almost there :)
   % Get the points in the selected triangles closest to the intersects
   
   
   
   % Finally, we probably have a selection of points. Pick the one that's closest to the
   % axis entry
   % Loop through all the points computing distance to P1
   goodPointIndices=unique(goodPointIndices(:));
   bestDist=Inf;
   bestPoint=NaN;
   for thisPoint=1:length(goodPointIndices)
      thisDist=sqrt(sum((mesh.uniqueVertices(goodPointIndices(thisPoint))-twoPointsInL(1,:)).^2));
      if (thisDist<bestDist)
         bestDist=thisDist;
         bestPoint=goodPointIndices(thisPoint);
      end
   end
   
      
   close(6);
   figure(6);



startNode=bestPoint;
