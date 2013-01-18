function allPosVar2D = rmPositionVariance2D(view, voxel, samp)
%
% rmPositionVariance2D - calculate the visual area size covered by the pRF 
% centers of surrounding nodes, normalized by cortical area size (per 1 mm^2)
% 
%  allPosVar2D = rmPositionVariance2D(view, voxel, samp)
%
% INPUT
%  view: VOLUME view should be provided
%  voxel: voxel size in mm (default = 1.5) 
%  samp: sampling of neurons within a voxel (default=1) 
%        1: uniform sampling, 2: gaussian sampling
% OUTPUT
%  allPosVar2D: 2D position variance (sigma)
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

allPosVar2D=zeros(1,size(nodes,2));

X = view.rm.retinotopyModels{1}.x0;
Y = view.rm.retinotopyModels{1}.y0;

for ii=1:size(nodes,2)
    tri=[];
    neighbors_pRF_area = 0;
    neighbors_cort_area = 0;
    X_tmp = X(ii);
    Y_tmp = Y(ii);
    tmp=1;
    if nodes(6,ii)==1   % use the nodes in layer 1
        neighbors = edges(:, edgeOffsets(ii):edgeOffsets(ii)+numNeighbors(ii)-1);
        % calculate neighbors only in layer 1
        remove_nodes=find(nodes(6,neighbors)~=1);
        neighbors(remove_nodes)=[];
        
        if size(neighbors,2)>=3
            % Calculate the visual field size covered by pRF centers of neighboring
            % nodes
            for jj=1:size(neighbors,2) % remove neighbors having the same pRF center
                if sum(X_tmp==X(neighbors(jj))|Y_tmp==Y(neighbors(jj)))==0
                    X_tmp = [X_tmp X(neighbors(jj))];
                    Y_tmp = [Y_tmp Y(neighbors(jj))];
                end
            end
            if size(X_tmp,2)>=3 % remove the case where all points are on a single line
                for kk=3:size(X_tmp,2)
                    tmp=tmp & (X_tmp(kk)-X_tmp(2))/(X_tmp(1)-X_tmp(2))*(Y_tmp(1)-Y_tmp(2))+Y_tmp(2)==Y_tmp(kk);
                end
                if tmp~=1
                    % get triangles in visual field to calculate visual
                    % field coverage
                    tri_visual = delaunay(X_tmp,Y_tmp);
                    % calculate the sum of the area size of all triangles
                    for num=1:size(tri_visual,1)
                        a = norm([X_tmp(tri_visual(num,1))-X_tmp(tri_visual(num,2)) Y_tmp(tri_visual(num,1))-Y_tmp(tri_visual(num,2))]);
                        b = norm([X_tmp(tri_visual(num,2))-X_tmp(tri_visual(num,3)) Y_tmp(tri_visual(num,2))-Y_tmp(tri_visual(num,3))]);
                        c = norm([X_tmp(tri_visual(num,1))-X_tmp(tri_visual(num,3)) Y_tmp(tri_visual(num,1))-Y_tmp(tri_visual(num,3))]);
                        s = (a+b+c)/2;

                        neighbors_pRF_area = neighbors_pRF_area + sqrt(s.*(s-a).*(s-b).*(s-c));
                    end
                end
            end
            
            % Calculate the cortical area size covered by neighboring nodes

            % get triangles in cortex to calculate cortical area size
            for jj=1:size(neighbors,2)
                neighbors_tmp = edges(:,edgeOffsets(neighbors(jj)):edgeOffsets(neighbors(jj))+numNeighbors(neighbors(jj))-1);
                remove_nodes_tmp = find(nodes(6,neighbors_tmp)~=1);
                neighbors_tmp(remove_nodes_tmp)=[];
                for kk=1:size(neighbors_tmp,2)
                    if size(find(neighbors_tmp(kk)==neighbors),2)~=0
                        tmp = sort([ii neighbors(jj) neighbors_tmp(kk)]);
    %                     if size(find(sum((tri-ones(size(tri,1),1)*sort([ii neighbors(jj) neighbors_tmp(kk)]))')'==0),1)
                        if size(tri,1)==0 | (size(tri,1)>0 & ~(sum(tri(:,1)==tmp(1))*sum(tri(:,2)==tmp(2))*sum(tri(:,3)==tmp(3))))
                            tri=[tri;tmp];
                        end
                    end
                end
            end
            % calculate the sum of the cortical area size
            for num=1:size(tri,1)
                a = norm([nodes(1,tri(num,1))-nodes(1,tri(num,2)) nodes(2,tri(num,1))-nodes(2,tri(num,2)) nodes(3,tri(num,1))-nodes(3,tri(num,2))]);
                b = norm([nodes(1,tri(num,2))-nodes(1,tri(num,3)) nodes(2,tri(num,2))-nodes(2,tri(num,3)) nodes(3,tri(num,2))-nodes(3,tri(num,3))]);
                c = norm([nodes(1,tri(num,3))-nodes(1,tri(num,1)) nodes(2,tri(num,3))-nodes(2,tri(num,1)) nodes(3,tri(num,3))-nodes(3,tri(num,1))]);
                s = (a+b+c)/2;
                
                neighbors_cort_area = neighbors_cort_area + sqrt(s.*(s-a).*(s-b).*(s-c));            
            end
        end
        allPosVar2D(ii) = neighbors_pRF_area/neighbors_cort_area;
    end
end

% multiply voxel size and transform into standard deviation
% uniform sampling in voxel
if samp==1  
    allPosVar2D(ii) = sqrt(allPosVar2D(ii))*voxel/sqrt(3);
% gaussian sampling in voxel (diameter of the scatter area is assumed to be fwhm)
elseif dist==2  
    allPosVar2D(ii) = sqrt(allPosVar2D(ii))*voxel/sqrt(2*log(2));
end

return;
