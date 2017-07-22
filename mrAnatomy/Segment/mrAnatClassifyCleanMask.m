function [mask]= mrAnatClassifyCleanMask(mask,minClusterSize)
% mrAnatClassifyCleanMask - remove small clusters
% [mask]= mrAnatClassifyCleanMask(mask,minClusterSize);

% 16-Jun-2005 SOD wrote it

if nargin < 1, help(mfilename); return; end;

if ieNotDefined('minClusterSize'), minClusterSize = 9; end;

% keep input
orgmask = mask;

% clean mask forground (1)
[LabMask remove]=myClipCluster(orgmask,minClusterSize);
fprintf('[%s]:Removing clusters (1):',mfilename);
for n=1:length(remove),
    mask(LabMask==remove(n))=0;
    fprintf('.');drawnow;
end
fprintf('Done.\n');drawnow;

% clean mask background (0)
[LabMask remove]=myClipCluster(-1.*orgmask+1,minClusterSize);
fprintf('[%s]:Removing clusters (0):',mfilename);
for n=1:length(remove),
    mask(LabMask==remove(n))=1;
    fprintf('.');drawnow;
end
fprintf('Done.\n');drawnow;


%-------------------------
function [imgLabel, remove]=myClipCluster(m,t)

% connectivity
%        6     three-dimensional six-connected neighborhood
%        18    three-dimensional 18-connected neighborhood
%        26    three-dimensional 26-connected neighborhood
conn = 6;

% get clusters
[imgLabel,numObjects] = bwlabeln(m, 6);

% get sizes
[imgHist,labelNum] = hist(imgLabel(:),0:numObjects);

% clean mask
remove = labelNum(find(imgHist(2:end)<t))+1;
 
return;

