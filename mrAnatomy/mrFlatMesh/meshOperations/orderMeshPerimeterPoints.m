function orderedPoints=orderMeshPerimeterPoints(perimeterEdges)
%
% orderedPoints=orderMeshPerimeterPoints(perimeterEdges)
%
% AUTHOR:  Wade
% PURPOSE:
% Takes a list of edges defined as point pairs.. 
% Returns the points in the list in their connection order...
% This is a fragile routine at the moment - can break under a number of unusual conditions
%
%  N.B.  Each vertex should appear in exactly two rows.
%  Starting with an initial position on the perimeter, startNode, the routine finds
%  

nPeriEdges=length(perimeterEdges);

startNode=perimeterEdges(1);
thisNode=-9999;
counter=1;
thisRow=1;thisCol=1;

while ((thisNode~=startNode) & (counter<=(nPeriEdges+1)))
   otherCol=(thisCol==1)+1; 
   thisNode=perimeterEdges(thisRow,otherCol);
  
   edgesToSearch=[1:(thisRow-1),(thisRow+1):nPeriEdges];
   lastRow=thisRow;
   
   % Have an edge, with two points. Pick one point and find the other edge in the list of
   % Perimeter edges that contains the point. Repeat until all points 
   % are covered or you've done more iterations
   % than there are edges...
   if (length(thisNode)~=1)
      disp ('Error! thisNode size is');
      disp (size(thisNode))
      disp ('thisRow=')
      disp (thisRow(:,:));
      disp ('thisCol=');
      disp (thisCol(:,:));
      
      break;
   end
   
   if (~isempty(edgesToSearch))
      [thisRow,thisCol]=find(perimeterEdges(edgesToSearch,:)==thisNode);
   else
   disp('No further edges to search!');
   break;
end

   if (thisRow>=lastRow) 
      thisRow=thisRow+1;
   end
   orderedPoints(counter)=thisNode;
   counter=counter+1;
end

if ((counter>nPeriEdges+1) | (counter<nPeriEdges+1))
   disp ('Something went wrong with the perimeter ordering!');
   fprintf ('\n%d edge classifications expected',nPeriEdges);
   fprintf ('\n%d steps performed',counter-1);
   
   %disp (orderedPoints);
   
   break; 
end

