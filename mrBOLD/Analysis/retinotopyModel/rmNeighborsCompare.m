function s_mm=rmNeighborsCompare(vw,model)
%  rmNeighborsCompare - compute pRF size in mm weighted by variance
%  explained
%
% 2009/02: SD & BH wrote it.

if ~exist('vw','var') || isempty(vw), error('Need view struct'); end
if ~exist('model','var') || isempty(model), error('Need rm model file'); end


% get gray connection structure
gNodes = viewGet(vw,'nodes');
gEdges = viewGet(vw,'edges');
coords = viewGet(vw,'coords');

% load model params
x = rmGet(model,'x');
y = rmGet(model,'y');
s = rmGet(model,'sigma');
ve = rmGet(model,'varexp');

% output
s_mm = zeros(size(s));

nGnodes=length(gNodes);

tic;
fprintf('[%s]:Computing...',mfilename);
for t=1:nGnodes % for each gNode...
    % Find its edges (the nodes of the things that it's connected to...)
    thisOffset=gNodes(5,t);
    thisNumEdges=gNodes(4,t);
    theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?        
    
    % variance explained for the neighbors
    ven = ve(theseEdges);
    ven = ven./sum(ven);
    
    % compute cortical distance from neighbors
    cdist = coords(:,theseEdges);  
    cdist = cdist - (coords(:,t)*ones(1,size(cdist,2)));
    cdist = sum(sqrt(sum(cdist.^2)).*ven);    % distance

    % compute distance from neighbors in visual field
    vfdist = [x(theseEdges); y(theseEdges)];
    vfdist = vfdist - ([x(t); y(t)]*ones(1,size(vfdist,2)));
    vfdist = sum(sqrt(sum(vfdist.^2)).*ven);
    
    % compute cortical pRF size
    s_mm(t) = s(t) * (cdist./vfdist);
end

% some are not finite when vfdist == 0, we interpolate these values
% we do this only for spurious voxels, large patches will be set to global
% mean
ii = find(~isfinite(s_mm));
for n=1:5
    for t=ii
        % Find its edges (the nodes of the things that it's connected to...)
        thisOffset=gNodes(5,t);
        thisNumEdges=gNodes(4,t);
        theseEdges=gEdges(thisOffset:(thisOffset-1+thisNumEdges)); %thisoffset-1 or 0?
        
        % lookup neighboring values with data
        nb = s_mm(theseEdges);
        nb = nb(isfinite(nb));
        
        if ~isempty(nb)
            s_mm(t) = mean(nb);
        end
    end
    ii = find(~isfinite(s_mm));
end

% any left we set to the global mean
ii = ~isfinite(s_mm);
s_mm(ii) = mean(s_mm(~ii));

fprintf('Done[%dsecs].\n',round(toc));

% rmGet(model,'s_mm');

return


