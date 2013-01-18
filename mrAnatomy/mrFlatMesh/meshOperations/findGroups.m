function groupedNodeStruct = findGroups(mesh,nodeList)
% Takes a list of nodes and tries to group it into unconnected unique clusters
%
%   groupedNodeStruct = findGroups(mesh,nodeList)
%
%


numVertices=length(mesh.connectionMatrix);
groupsFound=0;
currentGroup=1;

rowsToSearch=[1:numVertices];
foundAll=0;

searchConnectionMatrix=mesh.connectionMatrix(nodeList,nodeList);

counter=0;

while (~foundAll)
   nodesFoundThisTime=1;
   allNodesFound=[];
   [startNode x]=find(searchConnectionMatrix);
   currentNodes=startNode(1); % First non-zero row is the initial node
  
   
   while(nodesFoundThisTime)
      [y connectedNodes]=find(searchConnectionMatrix(currentNodes,:));
      connectedNodes=unique(connectedNodes(:));  % All the things connected to current node set
      nodesFoundThisTime=length(connectedNodes);
      
      if (nodesFoundThisTime)
         searchConnectionMatrix(:,currentNodes)=0;
         allNodesFound=[allNodesFound;connectedNodes];
         currentNodes=connectedNodes;
         
      end % if nothing found
     
      
   end % Loop while you're finding something
   groupedNodeStruct{currentGroup}.nodeList=unique(nodeList(allNodesFound));
   groupedNodeStruct{currentGroup}.tempList=unique(allNodesFound);
   currentGroup=currentGroup+1;
   
   foundAll=~(sum(searchConnectionMatrix(:)));
   
   counter=counter+1;
   disp(counter);
   

end

fprintf('%d groups found',counter);

% Re-generate this...
searchConnectionMatrix=mesh.connectionMatrix(nodeList,:);
searchConnectionMatrix=searchConnectionMatrix(:,nodeList);
searchConnectionMatrix=searchConnectionMatrix;


 



      