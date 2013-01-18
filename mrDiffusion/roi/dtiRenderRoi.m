load('ROIs/CC')

h = guidata(1);
coords = h.rois(h.curRoi).coords;
% Re-index starting at 1
coords = coords-repmat(min(coords),size(coords,1),1)+1;
coords = round(coords);
voxels = zeros(max(coords));
ind = sub2ind(size(voxels), coords(:,1), coords(:,2), coords(:,3));
voxels(ind) = 1;
voxels = smooth3(voxels,'gaussian',5);
voxels = voxels>.2;

voxels = dtiCleanImageMask(voxels, 5);
mm = [1 1 1];
id = -1;
[id,wasOpen] = mrmCheckMeshServer(id, 'localhost');
[mesh,lights,tenseMesh] = mrmBuildMesh(uint8(voxels), mm, 'localhost', id);