function [orderedPoints,biggest,goodPerimEdges]=orderMeshPerimeterPointsAll_new(mesh,perimeterEdges)
%
% orderedPoints=orderMeshPerimeterPointsAll(perimeterEdges)
%
% AUTHOR:  Wade
% DATE: 062100
% PURPOSE:
% Takes a list of edges defined as point pairs.. 
% Returns the points in the list in their connection order...
% If more than one (unlinked) perimeter exists, return a structure containing all the separate ordered perimeters
%
%  N.B.  Each vertex should appear in exactly two rows.
%  Starting with an initial position on the perimeter, startNode, the routine finds
%  the other node in the row. By selectively deleting entries in the connection matrix
%  as we progress, we can use a simple find operation each time to give us the next node.
%  ARW 031401 : This routine is critical to the success of the opration. It will break when
%  a perimeter point is connected to more than two other perimeter points. How can this happen? (you ask). 
%  Well it can happen when two perimeters share a common point - like interlocking rings. In theory, I think you could have two perimeters sharing many
%  points. We deal with this in some sense in findGroupPerimeter when we eliminate nodes that are not part of any face but the 'just touching' condition
%  is a headache. Here's one solution...
%  The perimeter connection matrix should have 2 entries per row. If it doesn't then iteratively generate new ones with fewer connections until you have a 
% (large?) set of perimeter connection matrices with 2 entries per row. E.G. if row t has entries at x,y,z then generate three copies of the conmat,
% one with entries at x,y one with y,z and one with x,z.
% If it has four entries, then you generate  nchoosek(1:4,2) new matrices.
% (You can see how this might mount up if we have many bad points -  if you have two bad points, each generating 
% n conMats then you end up with n^2 conmats - fortunately they seem to be rare
% and anyway, connection matrices are sparse and perimeter connection matrices are small and sparse.
% Then just run the regular perimeter detection algorithm on all the conmats and pick the biggest final perimeter.


nVerts=length(mesh.connectionMatrix); % Total number of vertices in the full connection matrix

edgePoints=unique(perimeterEdges(:)); % List of nodes that are on the perimeter
[y x]=size(mesh.connectionMatrix); % = nVerts

% Generate a connection matrix using only the edges - make sure it's symmetric
ec=sparse(perimeterEdges(:,1),perimeterEdges(:,2),1,nVerts,nVerts);
ec=ec+ec';
edgeConMat=sparse((ec~=0));
nnz(edgeConMat)
[eY,eX]=size(edgeConMat);

% Now do something interesting: go through the edge connecton matrix and find all the rows that have more than 2 entries
% Split these up and do some record keeping - we generate new nodes
% Used for checking which perimeter is biggest
nConnects=sum(edgeConMat,2); % How many points on each row?

badPoints=find(nConnects>2);
nBadPoints=length(badPoints);
fprintf('There are %d bad points',nBadPoints);
conMatStack{1}=edgeConMat;

for thisBadPoint=1:nBadPoints
    fprintf('\nLegalizing bad point number %d',thisBadPoint);
    
	conMatStack=legaliseConMatRow(conMatStack,badPoints(thisBadPoint));
end


nConMats=length(conMatStack);
fprintf('\n%d different edge connection matrices',nConMats);

biggest=-Inf;
biggestSize=-Inf;
goodEdgeConMat=-1;

thisPerim=1; % Index of the current perimeter
nextRow=-99999; % Dummy

foundAllPerimeters=0; % Flag to say we've finished

% Now loop over all the connection matrices 
for thisConMat=1:nConMats
	edgeConMat=conMatStack{thisConMat};
	nnz(edgeConMat)
	while (~foundAllPerimeters)
   counter=1;
   [startRow startCol]=find(edgeConMat);
   if (~isempty(startRow)) % If there is one...
      
      startRow=startRow(1); % ...pick the first non-zero row in the edge connection matrix
      startCol=startCol(1); % Pick the first non-zero column.
      orderedPoints{thisPerim}.points=startRow;
      
      thisRow=startRow;
      deleteCol=startCol;
      nextRow=-Inf;
      foundEnd=0;
      edgeConMat(thisRow,deleteCol)=0; % Zero one of the entries in this row 

      while ((~foundEnd)&(counter<10000))      
     
         % Do the deletions
         edgeConMat(thisRow,deleteCol)=0; % Zero one of the entries in this row 
         edgeConMat(deleteCol,thisRow)=0; % Zero one of the entries in this row 

         [thisCol]=find(edgeConMat(thisRow,:));
         
         thisCol=unique(thisCol(:));
         if (length(thisCol)>1)
            disp ('Warning!! - thiscol has more than 1 entry:');
            disp (thisCol);
            disp ('Perim node is connected to many other perim nodes. Carrying on but expect trouble....');
            % Can we just ignore superfluous ones? We'll press ahead regardless...
         	thisCol=thisCol(1);   
         end
         
         if (~isempty(thisCol)) % If there >is< another point in this perimeter
            orderedPoints{thisPerim}.points=[orderedPoints{thisPerim}.points;thisCol];
             deleteCol=thisRow;
             thisRow=thisCol;
           
         else % We've found the end of the perimeter.
           % fprintf ('\n.');
         
            foundEnd=1;
            orderedPoints{thisPerim}.size=counter;
            
         end % endif
         counter=counter+1;
     
      end % end while not startRow
       
      if (orderedPoints{thisPerim}.size>biggestSize) % Have to return the index of the larges tperim
         biggestSize=orderedPoints{thisPerim}.size;
         biggest=thisPerim;
		 goodEdgeConMat=conMatStack{thisConMat};
      end % end size check
      
      fprintf('\n%d points');
      
   end % End if anything found to start with
    
     foundAllPerimeters=(nnz(edgeConMat)==0);
     thisPerim=thisPerim+1;
	end % End while not all perims found
end % Next con mat

fprintf('\nFound %d perimeters...',thisPerim-1);
[goodY,goodX]=find(triu(goodEdgeConMat));
goodPerimEdges=[goodY(:),goodX(:)];
