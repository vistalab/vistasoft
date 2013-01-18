function [passed_clusters] = plot(this,p_skip,cl,cluster_draw_thresh,only_cluster)

% plotDatabase(this,p_skip,cl,cluster_draw_thresh,only_cluster)
%
% this is pathway database
% 'cl' is vector with clustered path labels

if ~exist('p_skip','var')
    p_skip=1;
end
if ~exist('only_cluster','var')
    only_cluster = 0;
end
if ~exist('cluster_draw_thresh','var')
    cluster_draw_thresh = 0;
end

if exist('cl','var')
    cluster_sizes = hist(cl,[1:max(cl)]);
    npaths = sum(cluster_sizes);
    if (cluster_draw_thresh == 0)
        cluster_draw_thresh = floor(0.05*npaths);
    end
    n = sum(cluster_sizes > cluster_draw_thresh);
    passed_clusters = find(cluster_sizes > cluster_draw_thresh);
else
    passed_clusters = 0;
end

hold off;

if exist('cl','var')
    % Iterate over all clusters
    for c = 1:length(passed_clusters)
        ci = find( cl == passed_clusters(c) );
        % Iterate over all paths in clusters
        for i = 1:length(ci)
            p = ci(i);
            npts = length(this.pathways(p).xpos(1:p_skip:end));
            % Maybe I am supposed to only draw one particular cluster out of
            % the ones that passed
            if ( only_cluster == 0 || cl(p) == only_cluster)
                label = ones(1,npts)*c;
                tubeplot(this.pathways(p).xpos(1:p_skip:end),this.pathways(p).ypos(1:p_skip:end),this.pathways(p).zpos(1:p_skip:end),0.5,label);
                hold on;
            end
        end
    end
    colormap( jet );
    caxis( [1 length(passed_clusters)+1] );
else
    % Setting up rendering parameters
    for p = 1:length(this.pathways)
%         if p > 500
%             p 
%         end
        if(rand > 0 && length(this.pathways(p).xpos) >= 10)
            %tubeplot(pd(p).xpos,pd(p).ypos,pd(p).zpos,0.5,pd(p).xpos,10);
            %tubeplot(pd(p).xpos,pd(p).ypos,pd(p).zpos,0.5,ones(length(pd(p
            %).xpos),1));
            tubeplot(this.pathways(p).xpos(1:p_skip:end),this.pathways(p).ypos(1:p_skip:end),this.pathways(p).zpos(1:p_skip:end),0.5);
            hold on;
        end
    end
    colormap(jet);
end

axis([0 73*2 0 98*2 0 66*2])
daspect([1 1 1])

lighting phong;
hidden off;
%shading interp;

%plot3(45,0,50,'ro','LineWidth',10);