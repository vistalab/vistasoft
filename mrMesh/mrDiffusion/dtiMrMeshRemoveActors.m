function msh = dtiMrMeshRemoveActors(msh,slicesDirty)
%
%   msh = dtiMrMeshRemoveActors(msh,slicesDirty)
%
%Author: Wandell
%Purpose:
%   Remove the actors currently displayed in the mrMesh window.
%

if ieNotDefined('msh'), error('msh must be specified'); end
if ieNotDefined('slicesDirty'), slicesDirty = 1; end

% Find the fiber groups that have been displayed and thus have an actor
% number.  Remove them.
l = find(msh.fiberGroupActors);
if ~isempty(l), mrmSet(msh,'removeActors',msh.fiberGroupActors(l));
end

if(slicesDirty==1 & isfield(msh,'imgActors') & ~isempty(msh.imgActors))
    mrmSet(msh,'removeActors',msh.imgActors);
    msh.imgActors = [];
end

if(isfield(msh,'roiActors') & ~isempty(msh.roiActors))
    for(ii=find(msh.roiActors>0))
        clear t; t.actor = msh.roiActors(ii);
        mrMesh(msh.host, msh.id, 'remove_actor', t);
    end
    msh.roiActors = [];
end

return;
