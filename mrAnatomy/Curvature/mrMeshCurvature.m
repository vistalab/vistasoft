function grayValue = mrMeshCurvature ( mesh, nodes )
% Obsolete. Find the curvature value associated with each of the positions.  
% 
%   grayValue = mrMeshCurvature ( mesh, nodes )
%
% OBSOLETE.
% This routine takes about an hour on a whole hemisphere.
% 
% The curvature data could come from anywhere, but we have been
% getting them from mrGray mesh files.
% 
% INPUTS:
%   mesh:  The structure returned by mrReadMrM
%   gLocs3d is Nx2 and Nx3 matrices containing
%   corresponding 3d positions for gray matter.
%   
% SEE ALSO: mrReadMrM
% 
% AUTHOR:  Maher Khoury 
% DATE:    07.15.99
% 09.30.99 WAP & RFD: streamlined the algorithm a bit.  It's now
%          about 10x faster.
%
% (c) Stanford VISTA Team

disp('Sorting mesh vertices...');
[sMeshVertices,si] = sortrows(mesh.vertices,1);
uniqueX = unique(round(sMeshVertices(:,1)));
h = mrvWaitbar(0,'Building Hash Table...');
startFind = 1;
hashOffset = 1-min(uniqueX);
hash = zeros((max(uniqueX)-min(uniqueX)+1),1);
for ii = 1:length(uniqueX)
   xVal = uniqueX(ii);
   foundX = find(round(sMeshVertices(startFind:end,1))==xVal);
   hash(xVal+hashOffset) = foundX(1)+(startFind-1);
   startFind = hash(xVal+hashOffset);
   if ~mod(ii,10);
      mrvWaitbar(ii/length(uniqueX));
   end
end
close(h);

disp('Extracting colors...')

x = sMeshVertices(:,1);
y = sMeshVertices(:,2);
z = sMeshVertices(:,3);

% here, we can assume that R=G=B and just the the R (first column)
sMeshColor = mesh.rgba(si,1);

%% Switch off warning
warning off;

%% First pass, with distance threshold of 2 
% 
threshold = 2;
nodes = findLocalRGB(hash,hashOffset,y,z,sMeshColor,nodes,threshold);

% More passes with more lax thresholds, if needed
while sum(isnan(nodes(:,4))) & (threshold<20)
   threshold = threshold + 1;
   indices = find(isnan(nodes(:,4)));
   nodes(indices,:) = findLocalRGB(hash,hashOffset,y,z,sMeshColor,nodes(indices,:),threshold);
end

%% Output gray values found above
%
grayValue = nodes(:,4);
grayValue = scale(grayValue,1,64);

%% Set the warning back on
warning backtrace;

return;


function nodes = findLocalRGB(hash,hashOffset,y,z,meshColor,nodes,threshold)
% hash is a hash table of x-values into x,y,z mesh vertices

h = mrvWaitbar(0,['Threshold ' num2str(threshold)]);
for nodeNum=1:length(nodes),
   roundX = round(nodes(nodeNum,1));
   xMin = max(1,hash(max(1,min(length(hash),roundX+hashOffset-(threshold+0.5)))));
   xMax = min(length(y),hash(min(length(hash),max(1,roundX+hashOffset+(threshold+0.5)))));
   ySubset = find(abs(y(xMin:xMax)-nodes(nodeNum,2)) < threshold);
   zSubsetOfYsubset = find(abs(z(ySubset+(xMin-1))-nodes(nodeNum,3)) < threshold );
   indices = ySubset(zSubsetOfYsubset);
 %  indices  = find(	abs(y(xMin:xMax)-nodes(nodeNum,2)) < threshold &...
 %     					abs(z(xMin:xMax)-nodes(nodeNum,3)) < threshold );      
   nodes(nodeNum,4) = mean(meshColor(indices+(xMin-1)));
   if ~mod(nodeNum,100)
      mrvWaitbar(nodeNum/length(nodes));
   end
end
close(h);

return;
