% this script will compute an endpoint density map on a mesh
% make sure to load in dtiFiberUI:
% 1. dt6 of 1 subject
% 2. fibers from a group of subjects, in MNI or SIRL54 coords
% 3. ROI which we will use to screen half of the endppoints (the ones that are
% closest to its center of mass).
% 4. mesh of the same subject with dt6 (will need to compute vAnatomy
% xform)

% clear all;
h = guidata(gcf);

acpc2vertex = dtiGet(h,'curmeshtoacpcxform');

% CHECK ME: are the initVertex coords zero-indexed?
msh = h.mrVistaMesh.meshes(h.mrVistaMesh.curMesh);
vertAcPcCoords = mrAnatXformCoords(inv(acpc2vertex), msh.initVertices)';
nVerts = size(vertAcPcCoords,2);

doSubjectCount = true;
distThresh = 3;
densityThresh = [3 20]; % DY 10/2007 number of subjects
overlayModDepth = 0.3;
% prompt = {'Distance threshold (mm):',...
%         'Density threshold (0-1):',...
%         'Overlay modulation (0-1):'};
% defAns = {num2str(distThresh),num2str(densityThresh),num2str(overlayModDepth)};
% resp = inputdlg(prompt, '3d Surface Overlay Parameters', 1, defAns);
% if(isempty(resp)) disp('user canceled.'); return; end
% distThresh = str2num(resp{1});
% densityThresh = str2num(resp{2});
% overlayModDepth = str2num(resp{3});

subjectDensity = zeros(1,nVerts);
totalDensity = zeros(1,nVerts);
sumAll = true;
removeRoiEndpoints = true;
if(removeRoiEndpoints)
    roiCenterOfMass = mean(h.rois(h.curRoi).coords);
end
distThreshSq = distThresh^2;
for(ii=1:length(h.fiberGroups))
    nFibers = length(h.fiberGroups(ii).fibers);
    fiberEndpoints = zeros(3,nFibers*2);
    for(jj=1:nFibers)
        fiberEndpoints(:,(jj-1)*2+1:(jj-1)*2+2) = h.fiberGroups(ii).fibers{jj}(:,[1,end]);
    end
    if(removeRoiEndpoints)
        [junk, sqDist] = nearpoints(fiberEndpoints, roiCenterOfMass');
        firstInPairClosest = sqDist(1:2:end)<sqDist(2:2:end);
        furthest = [~firstInPairClosest; firstInPairClosest];
        fiberEndpoints = fiberEndpoints(:,furthest);
    end
    if(sumAll)
        % Avoid searching over vertices with no fiber endpoints nearby
        [vert2epMap, sqDist] = nearpoints(vertAcPcCoords, fiberEndpoints);
        vertInds = sqDist <= distThreshSq;
        curDensity = zeros(1,nVerts);
        for(kk=find(vertInds))
            dsq = (fiberEndpoints(1,:)-vertAcPcCoords(1,kk)).^2 ...
                 +(fiberEndpoints(2,:)-vertAcPcCoords(2,kk)).^2 ...
                 +(fiberEndpoints(3,:)-vertAcPcCoords(3,kk)).^2;
            curDensity(kk) = sum(double(dsq<distThreshSq));
        end
    else
        [ep2vertMap, sqDist] = nearpoints(fiberEndpoints, vertAcPcCoords);
        epInds = sqDist <= distThreshSq;
        curDensity = hist(ep2vertMap(epInds), [1:nVerts]);
    end
    subjectDensity = subjectDensity+double(curDensity>0);
    totalDensity = totalDensity+curDensity;
end
if(doSubjectCount)
  mapData = subjectDensity; % DY 10/2007: max is 9
else
  mapData = totalDensity;
end

% Keep the old colors (which should be the sulcal pattern).
oldColors = meshGet(msh,'colors');
% Convert map values to colormap values.
mapData(mapData>densityThresh(2)) = densityThresh(2);
% DY 10/2007: densityThresh = [3 20]
mapRange = [0 max(mapData(:))];
% DY 10/2007: mapRange = [0 9]
if(mapRange(2)==0) error('no fibers in overlay map!'); end
mapData = round(mapData./max(mapData).*256);
cmap = [linspace(192,255,256)', linspace(0,255,256)', repmat(0,256,1)];
cmap([0:round(densityThresh(1)./mapRange(2)*255)]+1,:) = NaN;
newColors = repmat(NaN, size(oldColors(1:3,:)));
validInds = mapData>0;
newColors(:,validInds) = cmap(mapData(validInds),:)';
% Mask out vertices who don't have an above-threshold value within
% threshDist are below threshold (they are marked with NaNs).
dataMask = ~isnan(newColors(1,:));
if(overlayModDepth>0)
    newColors(:,dataMask) = (1-overlayModDepth)*newColors(:,dataMask) ...
        + overlayModDepth*double(oldColors(1:3,dataMask));
end
newColors(:,~dataMask) = oldColors(1:3,~dataMask);
newColors(newColors>255) = 255;
newColors(newColors<0) = 0;
mrmSet(msh,'colors',uint8(round(newColors')));

if(doSubjectCount)
  mrUtilMakeColorbar(cmap./255,linspace(mapRange(1),mapRange(2),5),'Subject count','subjectDensityLegend');
else
  mrUtilMakeColorbar(cmap./255, linspace(mapRange(1),mapRange(2),5),'Fiber Density','totalDensityLegend');
end
