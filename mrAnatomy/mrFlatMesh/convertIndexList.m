function newIndices=convertIndexList(indicesToConvert,fullSubNodeList)
% Conceptually very simple: we define a sub mesh from a set of nodes (fullSubNodeList)
% we can use this to, for example, create a connection matrix for the sub mesh by 
% newCM=oldCM(fullSubNodeList,fullSubNodeList)
% We also want to be able to convert arbitrary nodes from the old to the new mesh
% So for example, out list of faces in the old list is held as Fo(a,b,c) where (a,b,c) are
% node indices.
% If we can convert these to their new node indices (assuming that they exist in the new mesh)
% it would be a good thing. 
% So this routine (almost a single line) takes a list of N old mesh node indices and the list of nodes that are in
% the new mesh and returns a list of N indices giving the corresponding new mesh indices or NaN if the old
% node is not in the new mesh.

newIndicesFlags=ismember(indicesToConvert,fullSubNodeList);
f=find(newIndicesFlags);
newIndices=repmat(NaN,length(newIndicesFlags),1);
newIndices(f)=f;
