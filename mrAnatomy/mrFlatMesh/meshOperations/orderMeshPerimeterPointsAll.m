function [orderedPoints,biggest]=orderMeshPerimeterPointsAll(mesh,perimeterEdges)
% Take a set of mesh points on a perimeter and order them by their connections
%
%  orderedPoints=orderMeshPerimeterPointsAll(perimeterEdges)
%
% If more than one (unlinked) perimeter exists, return a structure
% containing all the separate ordered perimeters.
%
% N.B.  Each vertex should appear in exactly two rows.
% Starting with an initial position on the perimeter, startNode, the routine finds
% the other node in the row. By selectively deleting entries in the connection matrix
% as we progress, we can use a simple find operation each time to give us the next node.
% 
% AUTHOR:  Wade
% DATE: 200-06-21

foundAllPerimeters=0; % Flag to say we've finished
nVerts=length(mesh.connectionMatrix); % Total number of vertices in the full connection matrix

edgePoints=unique(perimeterEdges(:)); % List of nodes that are on the perimeter
[y x]=size(mesh.connectionMatrix); % = nVerts

% Generate a connection matrix using only the edges - make sure it's symmetric
ec=sparse(perimeterEdges(:,1),perimeterEdges(:,2),1,nVerts,nVerts);
ec=ec+ec';
edgeConMat=(ec~=0);
%nnz(edgeConMat)

% Used for checking which perimeter is biggest
biggest=-Inf;
biggestSize=-Inf;


thisPerim=1; % Index of the current perimeter
nextRow=-99999; % Dummy


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
        end % end size check
        
        fprintf('%d points\n');
        
    end % End if anything found to start with
    
    %keyboard;
    %nnz(edgeConMat)
    foundAllPerimeters=(x*y)-nnz(edgeConMat); %(sum(sum(edgeConMat==0)));
    thisPerim=thisPerim+1;
    %     disp(thisPerim);
    %     disp(nnz(edgeConMat));
    
end % End while not all perims found

fprintf('Found %d perimeters\n',thisPerim-1);

return;