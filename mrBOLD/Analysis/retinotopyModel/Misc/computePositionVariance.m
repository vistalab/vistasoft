function pv=computePositionVariance(view)
% computePostionVariance - compute position variance across
% cortical surface
%
% pv=computePositionVariance(view)
%
% 2008/05 SD & KA: wrote it

if ~exist('view','var') || isempty(view), error('Need view struct'); end
  
model = viewGet(view,'rmCurModel');

x = rmGet(model,'x0');
y = rmGet(model,'y0');
w = rmGet(model,'varexp');

edges        = double(view.edges);
numNeighbors = double(view.nodes(4,:));
edgeOffsets  = double(view.nodes(5,:));

pv = varOfNeighbors(x,y,w,edges,edgeOffsets,numNeighbors);

return
