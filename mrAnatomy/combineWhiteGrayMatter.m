function class=combineWhiteGrayMatter(classFile,grayFile,outClassFile)
% combinedWhiteGray=combineWhiteGrayMatter(classFile,grayFile)
% We often want to generate a 3D binary volume from the white and gray
% matter discarding the gray graph connectivity data
% This routine loads in a white class file. It throws away any information 
% about CSF. Then it loads a gray matter file. It then adds the gray
% matter into the white volume, setting all voxels to the 'white' value.
% The resulting class is saved out as a new file 
class=readClassFile(classFile);
% Remove CSF
class.data(class.data==48)=0;

grayGraph=readGrayGraph(grayFile);
%   RETURNS:
%   nodes:  8xN array of 
%      Nx(x,y,z,num_edges,edge_offset,layer,dist,pqindex).
%   edges:  1xM array of node indices.  The edge_offset of
%      each node points into the starting location of its set
%      of edges.
%   where N, M are the number of nodes, edges in the graph.
%   vSize = size of the original volume of data containing the anatomicals

volSize=[class.header.xsize class.header.ysize class.header.zsize ]
gcoords=grayGraph([1 2 3],:);
gcoordsInd=sub2ind(volSize(:)',gcoords(1,:)',gcoords(2,:)',gcoords(3,:)');

% keyboard
% x=zeros(256,256,256);
% y=class.data;
% x(gcoordsInd)=16;
% y(gcoordsInd)=16;
% p=squeeze(x(100,:,:));
% figure(1);
% subplot(2,1,1);
% imagesc(p);
% p2=squeeze(y(100,:,:));
% subplot(2,1,2);
% imagesc(p2);



class.data(gcoordsInd)=16;
size(gcoordsInd)

class=writeClassFile(class,outClassFile);
