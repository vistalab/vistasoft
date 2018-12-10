spm_defaults;

[f, p] = uigetfile('*.mat', 'Select sn-file...');
if(isnumeric(f)) error('User canceled'); end
sn = load(fullfile(p,f));

[f, p] = uigetfile({'*.mnc','MINC format';'*.img','Analyze 7.5 format (*.img)'}, 'Select volume file to unwarp...');
if(isnumeric(f)) error('User canceled'); end

interpMethod = 1; % 1= trilinear, 7= 7th-order 
disp('Loading volume to-be-unwarped...');
V = spm_vol(fullfile(p,f));

% The following will compute the appropriate bounding box for the original
% image (sn.VF), so we will just take that as our target voxel-space.
disp('Computing inverse deformation (may take a while)...');
[defX, defY, defZ] = mrAnatInvertSn(sn);
h = mrvWaitbar(0,'Warping map to current brain...');
defSize = size(defX);
img = zeros(defSize);
x = [1:defSize(1)];
y = [1:defSize(2)];
nz = defSize(3);
for(z=1:nz)
    [X,Y,Z] = ndgrid(x, y, z);
    sc =  [X(:) Y(:) Z(:) ones(size(X(:)))]';
    scInd = sub2ind(defSize, sc(1,:), sc(2,:), sc(3,:));
    tc = double([defX(scInd); defY(scInd); defZ(scInd)]);
    % Now convert the deformed coordinates (in physical space) to the voxel space of
    % the normalized image that we are unwarping (V).
    tc = inv(V.mat)*[tc;ones(size(tc(1,:)))];
    img(:,:,z) = reshape(spm_sample_vol(V, tc(1,:), tc(2,:), tc(3,:), interpMethod),size(img(:,:,1)));
    mrvWaitbar(z/nz,h);
end
close(h);
figure; imagesc(makeMontage(img)); axis image; colorbar;

[f,p] = uiputfile('*.img', 'Save unwarped volume as...');
if(isnumeric(f)) error('User canceled- results NOT saved!'); end
Vo.fname = fullfile(p,f);
Vo.dim = [size(img) spm_type('uint8')];
Vo.mat = sn.VF.mat;
Vo = spm_write_vol(Vo,img);
