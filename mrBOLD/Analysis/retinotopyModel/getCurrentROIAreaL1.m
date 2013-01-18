function view=getCurrentROIAreaL1(view)

%Calculates the mesh surface area of the current ROI in the current mesh.
%Requires a mesh to be open, and an ROI to be selected
%Makes sure correct ROI is selected for correct mesh (eg, RightV1 ROI,
%RightSmooth mesh)

global selectedVOLUME

selectedVOLUME = viewSelected('volume'); 
msh = viewGet(view,'currentmesh');
view=roiSetVertInds(view);
if strcmp(msh.name, 'leftSmooth')
    mshVertices=view.ROIs(view.selectedROI).roiVertInds.leftSmooth;
elseif strcmp(msh.name, 'rightSmooth')
    mshVertices=view.ROIs(view.selectedROI).roiVertInds.rightSmooth;
end

[areaList, smoothAreaList] = mrmComputeMeshArea(msh, mshVertices.layer1);
fprintf('ROI surface area: %0.1f mm^2 (%0.1f mm^2 on smoothed mesh)\n', sum(areaList), sum(smoothAreaList));
end

