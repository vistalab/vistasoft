function allPosVar1D = rmPositionVariance1D(view, voxel, samp)
%
% rmPositionVariance1D - calculate averaged 1D position variance for each
% voxel. First, averaged difference in pRF center between each voxel and  
% its surrouding voxels, normalized by corresponding cortical distance, is 
% calculated. To get pRF center change between neighborsing voxels, and 
% thus the diametor of neuronal RF center scatter within a voxel, voxel 
% size is multipled (by default, 1.5 mm voxel is assumed). Fianlly, the 
% diameter is transformed into sigma, assuming uniform sampling (diameter = 
% width of the sampling) or gaussian sampling (diameter = fwhm) of neurons. 
% 
%  allPosVar1D = rmPositionVariance1D(view, voxel, samp)
%
% INPUT
%  view: VOLUME view should be provided
%  voxel: voxel size in mm (default = 1.5) 
%  samp: sampling of neurons within a voxel (default=1) 
%        1: uniform sampling, 2: gaussian sampling
% OUTPUT
%  allPosVar1D: 1D position variance (sigma)
%
%
% KA wrote it 08/10

if ieNotDefined('view')
    view = getCurView;
end
if ieNotDefined('voxel')
    voxel = 1.5;
end
if ieNotDefined('samp')
    samp = 1;
end

nodes   = double(view.nodes);
edges   = double(view.edges);
numNeighbors = double(view.nodes(4,:));
edgeOffsets  = double(view.nodes(5,:));

allPosVar1D=zeros(1,size(nodes,2));

X = view.rm.retinotopyModels{1}.x0;
Y = view.rm.retinotopyModels{1}.y0;

for ii=1:size(nodes,2)
    if nodes(6,ii)==1
        % get neighboring nodes
        neighbors = edges(:, edgeOffsets(ii):edgeOffsets(ii)+numNeighbors(ii)-1);
        % use the nodes in layer 1
        remove_nodes=find(nodes(6,neighbors)~=1);
        neighbors(remove_nodes)=[];
        
        % cortical distance from the current node to its neighboring nodes
        neighbors_cort_dist = sqrt(sum((nodes(1:3,neighbors)-nodes(1:3, ii)*ones(1,size(neighbors,2))).^2));
        
        % pRF center of neighboring nodes
        neighbors_pRFcenters = [X(neighbors);Y(neighbors)];
        neighbors_pRF_dist = sqrt(sum((neighbors_pRFcenters - [X(ii);Y(ii)]*ones(1,size(neighbors,2))).^2));
        
        % pRF center change per 1mm cortical distance, averaged across neighboring nodes
        allPosVar1D(ii) = mean(neighbors_pRF_dist./neighbors_cort_dist);
    end
end

% multiply voxel size and transform into standard deviation
% uniform sampling in voxel
if samp==1  
    allPosVar1D(ii) = allPosVar1D(ii)*voxel/sqrt(3);
% gaussian sampling in voxel (diameter of the scatter area is assumed to be fwhm)
elseif dist==2  
    allPosVar1D(ii) = allPosVar1D(ii)*voxel/sqrt(2*log(2));
end

return;
