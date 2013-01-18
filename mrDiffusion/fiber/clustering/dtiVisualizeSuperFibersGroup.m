function   dtiVisualizeSuperFibersGroup(SuperFibersGroup, nodecolors, nodecolorspropertyname)

%%Various ways to visualize superfibers. SuperFibersGroup: 1xN array of
%%superfibers.
%nodecolors: numNodesXN matrix fa values along the node...

%ER 02/2008 SCSNL
if(~exist('nodecolorspropertyname', 'var')|| isempty(nodecolorspropertyname))
    nodecolorspropertyname = 'property X';
end

bb=[ -80 80   -120    90   -60    90]';

nfibers=length(SuperFibersGroup);
    numNodes=size(SuperFibersGroup(1).fibers{1}, 2); %These are means


for i=1:nfibers
    curves(:, :, i)=SuperFibersGroup(i).fibers{1};
    varmx(:, :, i)=SuperFibersGroup(i).fibervarcovs{1};
    
end

figure; 

for clust=1:nfibers
    subplot(1, 2, 1); 
    
    %(Option 1)
    %Display a tubeplot with central line along the SuperFiber node means, and
    %with radius supplied by generalized variance???
    %tubeplot(curves(1, :, clust), curves(2, :, clust), curves(3, :, clust), RADIUS, COLOR);
    
    for nodeI=1:numNodes
        [determinant, varcovmatrix] =detLowTriMxVectorized(varmx(:, nodeI, clust));
        genvar(nodeI, clust)=sqrt(trace(diag(eig(varcovmatrix)))./3);
    end
    tubeplot(curves(1, :, clust), curves(2, :, clust), curves(3, :, clust), genvar(:, clust), nodecolors(:, clust));  %CHECK THIS!!!!! THAT SQRT of TRACE of EIGENVALUES is 2bused. MAYBE NOT TRACE BUT AVERAGE?
    %This plots genvar at 1SD, can do 2...to cover 73%or so...
    hold on;
    %axis(bb(:));
    xlabel('L<->R'); ylabel('P<->A'); zlabel('I<->S'); grid on;
    
    text(curves(1, 1), curves(2, 1), curves(3, 1),'ROI1');
    text(curves(1, end), curves(2, end), curves(3, end),'ROI2');
    alpha(.5);colorbar('Location','NorthOutside');     
    subplot(1, 2, 2); plot(nodecolors); title({nodecolorspropertyname,  ' along the fiber (colorcoded)'}); hold on;
 xlabel ('Node (ROI1 to ROI2)'); 

end
ylabel(nodecolorspropertyname); 
%(Option 2)
%THIS SNIPPET DRAWS UGLY ELLIPSOIDS
%SD=2.0 covers ~73%  of the total probability mass (SD=1:  ~ 19%)
if 0
    
    SD=1;
    figure;
    
    for clust=1:size(SuperFibersGroup.n, 2)
        
        for nodeI=1:numNodes
            [determinant, varcovmatrix] =detLowTriMxVectorized(varmx(:, nodeI, clust));
            plot_gaussian_ellipsoid(curves(:, nodeI, clust), varcovmatrix, SD);    hold on;
        end
        axis(bb(:));
        xlabel('L<->R'); ylabel('P<->A'); zlabel('I<->S'); grid on;
        
        hold on;
        text(curves(1, 1), curves(2, 1), curves(3, 1),'ROI1')
        text(curves(1, end), curves(2, end), curves(3, end),'ROI2')
        
    end
end

%Option X --TODO
%THIS SNIPPET will make individual fiber tubes for this cluster. Need to
%have the original FG which the SuperFiber was computed from
%subplot(2, 1, 2); dtiVisualizeClusterOfFibers.m(clust, clusterlabels,  fg); title(['Cluster' num2str(clust) ' nfibers ' num2str(size(find(clusterlabels==clust), 1))]);


