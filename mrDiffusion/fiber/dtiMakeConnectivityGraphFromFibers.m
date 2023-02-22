function connGraph = dtiMakeConnectivityGraphFromFibers(distThresh, fgFile, foldedMeshFile, flatMeshFile, xformFile, mniLutFile)
% Obsolete:
% Make connectivity graph for vertices on the flat mesh.  The flat mesh is a
% subset of the vertices in the foldedMesh.  The folded mesh vertices will
% also be assigned a fiber index if they are within some distance from a
% fiber endpoint.  
% 
% connGraph = dtiMakeConnectivityGraphFromFibers(distThresh, fgFile, foldedMeshFile, flatMeshFile, xformFile, mniLutFile)
%
%
% 
% HISTORY:
% 2007.06.27 AJS: wrote it.
%

error('Obsolete: %s\n',mfilename);

return

fg = dtiReadFibers(fgFile);
mshFolded = load(foldedMeshFile);
mshFolded = mshFolded.msh;
mshFlat = mrmLoadOffFile(flatMeshFile);
connGraph.mshFolded = mshFolded;
connGraph.mshFlat = mshFlat;
% Fix parent indices, from SurfRelax format to matlab 1-index
connGraph.mshFlat.parentInds = connGraph.mshFlat.parentInds+1;

load(xformFile);
fg = dtiXformFiberCoords(fg, inv(xformVAnatToAcpc));
distSqThresh = distThresh.^2;
coords = zeros(length(fg.fibers)*2, 3);
for ii=1:length(fg.fibers)
    if ~isempty(fg.fibers{ii})
        % We only look at fiber endpoints (first and last point)
        coords((ii-1)*2+1,:) = fg.fibers{ii}(:,1)';
        coords((ii-1)*2+2,:) = fg.fibers{ii}(:,end)';
    else
        coords((ii-1)*2+1,:) = [nan, nan, nan];
        coords((ii-1)*2+2,:) = [nan, nan, nan];
    end
end
coords(isnan(coords(:,1)),:) = [];
coords = coords(:,[2,1,3]);

% Get vertex indices for the endpoints of the fibers
% inputs should be 3xN
[endInds, bestSqDist] = nearpoints(coords',mshFolded.initVertices);
endInds = reshape(endInds,2,size(endInds,2)/2);
bestSqDist = reshape(bestSqDist,2,size(bestSqDist,2)/2);
endInds(bestSqDist>distSqThresh) = 0;
connGraph.fiberEndInds = endInds;
connGraph.fiberPos1 = coords(1:2:end,:)';
connGraph.fiberPos2 = coords(2:2:end,:)';
connGraph.fiberLengths = zeros(1,length(connGraph.fiberEndInds));
for ff=1:length(fg.fibers) 
    connGraph.fiberLengths(ff) = length(fg.fibers{ff});
end

% Get labels for all mesh vertices
% To use the transform:
ni = niftiRead(mniLutFile);
xform.coordLUT = ni.data;
xform.inMat = ni.qto_ijk;
% Mesh is stored in VAnat space for visualization
t1AcpcCoords = mshFolded.initVertices([2,1,3],:);
t1AcpcCoords = mrAnatXformCoords(xformVAnatToAcpc,t1AcpcCoords);
mniCoords = mrAnatXformCoords(xform, t1AcpcCoords);
connGraph.aLabels = zeros(length(mniCoords),1);
connGraph.bLabels = zeros(length(mniCoords),1);
%connGraph.aLabelKey = dtiGetBrainLabel([],'MNI_AAL');
%connGraph.bLabelKey = dtiGetBrainLabel([],'MNI_Brodmann');
% TODO Find out how to remove this for loop
hWaitBar = [];
for ll=1:length(connGraph.aLabels)
    [foo connGraph.aLabels(ll)] = dtiGetBrainLabel(mniCoords(ll,:), 'MNI_AAL');
    [foo connGraph.bLabels(ll)] = dtiGetBrainLabel(mniCoords(ll,:), 'MNI_Brodmann');
%     if mod(ll,5000)==0
%         disp(['Labelled ' num2str(ll/length(connGraph.aLabels))*100 '%']);
%     end
    if isempty(hWaitBar)
        hWaitBar = mrvWaitbar(ll/length(connGraph.aLabels)*100,'Labelling...');
    else
        mrvWaitbar(ll/length(connGraph.aLabels)*100,hWaitBar);
    end
end


return;
