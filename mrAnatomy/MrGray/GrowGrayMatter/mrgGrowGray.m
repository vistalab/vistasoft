function [nodes,edges,classData] = mrgGrowGray(classData,numLayers,layer0,hemisphere)
%
%     [nodes,edges,classData] = mrgGrowGray(classInfo,[numLayers],[layer0],[hemisphere='left'])
%
% This routine calls the mex function grow_gray with the parameters
% specified by the user and loads the class file if necessary
%
% INPUTS :
%     - classInfo : a variable loaded from a class file or 
%                   a path string pointing to the class file
%     - numLayers : number of layers to grow the gray matter
%     - layer0 : optional input argument. (Default 0)
%                   - 0 : no white matter included in the gray graph
%                   - 1 : the white boundary included in the gray graph. 
%                         In this case, the layer number of the boundary will be 0. 
%                   - 2 : All the white matter fully connected is included
%                         in the gray graph
%
% OUTPUTS :
%     - nodes : structure containing nodes of the gray matter
%     - edges : structure containing edges of the gray matter
%     - classData : matlab class file structure containing the output
%
% Example:
%  To visualize a mesh with, say, two layers of gray superimposed do this.
%   fName=fullfile(mrvDataRootPath,'anatomy','anatomyV','left','left.Class');
%   [nodes,edges,classData] = mrgGrowGray(fName,2);
%   wm = uint8( (classData.data == classData.type.white) | (classData.data == classData.type.gray));
%   msh = meshColor(meshSmooth(meshBuildFromClass(wm,[1 1 1])));
%   meshVisualize(msh,2);
%
%  To see the gray matter and white matter in a slice, along with their
%  connectivity, use this.  Change the third argument of mrGrowGray to
%  change the type of connectivity you visualize.
%
%   fName ='X:\anatomy\nakadomari\left\20050901_fixV1\left.Class';
%   [nodes,edges,classData] = mrgGrowGray(fName,2,2);
%   mrgDisplayGrayMatter(nodes,edges,80,[120 140 120 140]);
%
% NOTE:  M. Schira says that the gray nodes should be more densely
% connected to reduce the error in the distance measurements.  We should
% look into completing the connections in mrGrowGray.
%
% HISTORY:
%  GB 01/11/06 wrote it.
%  2008.07.07 RFD: fixed bug in VOI clipping.
%  2008.12.19 DY: fixed hemisphere variable setting bug
%
% (c) Stanford VISTA Team, 2006

if notDefined('numLayers'),  numLayers = 3; end
if notDefined('layer0'), layer0 = 0; end
if notDefined('hemisphere'), hemisphere = 'left'; end
if ischar(classData), classData = readClassFile(classData,0,0,hemisphere); end

voi  = classData.header.voi;
data = classData.data;
% RFD: added the "| ... 160". I think this is the type code for 'selected
% gray matter', but it's not listed in 
data(data(:) == classData.type.gray) = classData.type.unknown;

fprintf('Growing %i gray layers...\n',numLayers);
if layer0, 
    fprintf('White matter included in the gray graph...\n'); 
else
    fprintf('White matter excluded in the gray graph...\n');
end

% Growgray should ignore extra labels, but doesn't-= so we 'clean' it's
% class data.
cleanData = data;
cleanData(cleanData>=classData.type.other) = classData.type.unknown;
[nodes,edges] = grow_gray(cleanData,numLayers,voi,layer0);

grayMatter = nodes(1:3,nodes(6,:) ~= 0)+1;
outOfVoi = grayMatter(1,:)<=voi(1) | grayMatter(1,:)>voi(2) ...
         | grayMatter(2,:)<=voi(3) | grayMatter(2,:)>voi(4) ...
         | grayMatter(3,:)<=voi(5) | grayMatter(3,:)>voi(6);
grayMatter(:,outOfVoi) = [];
data(sub2ind(size(data),...
    grayMatter(1,:) - voi(1),...
    grayMatter(2,:) - voi(3),...
    grayMatter(3,:) - voi(5))) = classData.type.gray;

classData.data = data;

return;
