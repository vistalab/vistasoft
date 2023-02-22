function makeNormalizedVectors(tensorFloatFile, sn3dFile, ifileName, outFileName, options)
%
% makeNormalizedVectors(tensorFloatFile, sn3dFile, ifileName, [outFileName], [options])
%
% eg. makeNormalizedVectors('dti/Tensor.float.001', 'sn3d.mat', 'dti/B0', '', {'showfigures'})
%
% HISTORY:
% 2003.06.05 RFD: wrote it.
%

% To get all children:
%[subjects, baseDir] = getSubjects('dc', 'c');
% To get adults:
%[subjects, baseDir] = getSubjects('dc', 'a')
%
% for(ii=1:length(subjects))
%    sub = subjects{ii};
%    base = fullfile(baseDir,sub);
%    tensorFloatFile = fullfile(base, 'dti', 'Tensor.float');
%    sn3dFile = fullfile(base,'dti_analyses',[sub '_B0_sn3d.mat']);
%    ifileName = fullfile(base,'dti','B0');
%    outFileName = fullfile(base,'dti_analyses',[sub,'_']);
%    makeNormalizedVectors(tensorFloatFile, sn3dFile, unnormalizedFileName, outFileName, {'showFigures'});
%    end

if(nargin<3)
    help(mfilename);
    return;
end
if(~exist('outFileName','var') | isempty(outFileName))
    outFileName = fullfile(fileparts(sn3dFile),'out_');
end
if(~exist('options')) options = {}; end
if(strmatch('showfigures', lower(options))) fig = 1;
else fig = 0; end

disp(['Loading tensor.float file "' tensorFloatFile '"...']);
[b0, fa, add, ci, meanDiff, maxEig, medEig, minEig, maxVec] = dtiLoadTensorcalc(tensorFloatFile);

% We will be applying the spm normalization step to the data. We will 
% need to adjust the vectors accordingly.
sn3d = load(sn3dFile);
p = spm_imatrix(sn3d.Affine);
% rotX = p(4); rotY = p(5); rotZ = p(6);
p([1:3,10:12]) = 0; % set translations & skews to 0
p([7:9]) = 1; % scales should be 1
% Invert the rotations
p([4:6]) = -p([4:6]);
xform = spm_matrix(p);
disp(sprintf('  sn3d affine rotations (x,y,z): %0.3f  %0.3f  %0.3f', p(4), p(5), p(6)));

nSlices = size(b0,3);

% The first two dims will get permuted when we write the data out to
% the analyze file (to put them in standard analyze axial form). But,
% we need to permute them here because tensorcalc permuted them
% relative to the original Ifiles.
maxVec = permute(maxVec,[2 1 3 4]);
% Since we just permuted voxel coordinates, we should also swap X and Y, 
% but it turns out that the tensorcalc convention makes X 
% anterior-posterior and Y left-right, but we want them to be the other 
% way to follow Talairach naming convention. So, we leave them as is.

%
% SAVE UNNORMALIZED VECTORS
%
% We use the I-file header from the I-file that was normalized so that
% makeAnalyzeFromRaw reorients things the same as it did for it.
disp(['  saving unnormalized vector files...']);
makeAnalyzeFromRaw(maxVec(:,:,:,1), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [outFileName,'vecX']);
makeAnalyzeFromRaw(maxVec(:,:,:,2), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [outFileName,'vecY']);
makeAnalyzeFromRaw(maxVec(:,:,:,3), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [outFileName,'vecZ']);

if(fig)
    [imgX, mmPerVox, hdr] = loadAnalyze([outFileName,'vecX']);
    imgX = imgX.*hdr.pinfo(1);
    imgY = loadAnalyze([outFileName,'vecY']);
    imgY = imgY.*hdr.pinfo(1);
    imgZ = loadAnalyze([outFileName,'vecZ']);
    imgZ = imgZ.*hdr.pinfo(1);
    clear m;
    m(:,:,1) = flipud(makeMontage(abs(imgX))');
    m(:,:,2) = flipud(makeMontage(abs(imgY))');
    m(:,:,3) = flipud(makeMontage(abs(imgZ))');
    m(m<0) = 0;
    m(m>1) = 1;
    figure; image(m); axis equal; axis off; title(['original']);
end

%
% NORMALIZE VECTOR DIRECTIONS
%
% We need to apply the affine rotation (xform) to the vectors so that
% they will be correctly oriented after the spatial normalization.
sz = size(maxVec);
maxVec = reshape(maxVec,prod(sz(1:3)),3)';
maxVec = xform*[maxVec; ones(1,size(maxVec,2))];
maxVec = reshape(maxVec(1:3,:)', sz);

%
% we save a tmp file here- the normalized vectors
% 
disp(['  saving temporary files...']);
tmp = tempname;
makeAnalyzeFromRaw(maxVec(:,:,:,1), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [tmp,'X']);
makeAnalyzeFromRaw(maxVec(:,:,:,2), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [tmp,'Y']);
makeAnalyzeFromRaw(maxVec(:,:,:,3), [ifileName,'.001'], sprintf('%s.%03d',ifileName,nSlices), nSlices, [tmp,'Z']);

if(fig)
    [imgX, mmPerVox, hdr] = loadAnalyze([tmp,'X']);
    imgX = imgX.*hdr.pinfo(1);
    imgY = loadAnalyze([tmp,'Y']);
    imgY = imgY.*hdr.pinfo(1);
    imgZ = loadAnalyze([tmp,'Z']);
    imgZ = imgZ.*hdr.pinfo(1);
    clear m;
    m(:,:,1) = flipud(makeMontage(abs(imgX))');
    m(:,:,2) = flipud(makeMontage(abs(imgY))');
    m(:,:,3) = flipud(makeMontage(abs(imgZ))');
    m(m<0) = 0;
    m(m>1) = 1;
    figure; image(m); axis equal; axis off; title(['vectors normalized']);
end

% These are the default SPM values for bounding box (bb) and voxel size:
disp(['  normalizing...']);
spm_defaults;
bb = sptl_BB; %[[-78 -112 -50];[ 78 76 85]];
vox = sptl_Vx; %[2 2 2];
interpMethod = 1;   % 0=nearest neighbor, 1=trilinear
spm_write_sn([tmp,'X'], sn3dFile, bb, vox, interpMethod);
spm_write_sn([tmp,'Y'], sn3dFile, bb, vox, interpMethod);
spm_write_sn([tmp,'Z'], sn3dFile, bb, vox, interpMethod);

disp(['  moving and renaming normalized files...']);
newName = [outFileName,'nvec'];
[p,f] = fileparts(tmp);
oldName = fullfile(p,['n' f]);
moveFile([oldName 'X.hdr'], [newName 'X.hdr']);
moveFile([oldName 'X.img'], [newName 'X.img']);
moveFile([oldName 'Y.hdr'], [newName 'Y.hdr']);
moveFile([oldName 'Y.img'], [newName 'Y.img']);
moveFile([oldName 'Z.hdr'], [newName 'Z.hdr']);
moveFile([oldName 'Z.img'], [newName 'Z.img']);

if(fig)
    [imgX, mmPerVox, hdr] = loadAnalyze([newName,'X']);
    imgX = imgX.*hdr.pinfo(1);
    imgY = loadAnalyze([newName,'Y']);
    imgY = imgY.*hdr.pinfo(1);
    imgZ = loadAnalyze([newName,'Z']);
    imgZ = imgZ.*hdr.pinfo(1);
    clear m;
    m(:,:,1) = flipud(makeMontage(abs(imgX))');
    m(:,:,2) = flipud(makeMontage(abs(imgY))');
    m(:,:,3) = flipud(makeMontage(abs(imgZ))');
    m(m<0) = 0;
    m(m>1) = 1;
    figure; image(m); axis equal; axis off; title(['fully normalized']);
end

return;

