function dt6 = dtiMakeDt6FromFsl(b0FileName, t1FileName)
%
% dt6 = dtiMakeDt6FromFsl([b0FileName], [t1FileName])
%
% Takes a set of images from FSL's DTI image files and saves them out as
% in a dt6 matlab file. You should specify the FSL S0 (usually b=0) file as
% input (a file dialog will pop-up if you don't).
%
% The t1 file is optional- if it is omitted, then the b=0 will be used as
% the anatomical reference.
%
% HISTORY:
% 2005.08.04 RFD (bob@white.stanford.edu) wrote it (based on dtiMakeDt6)

slice = [0,0,0]; % slice to display for checking coregistration
bb = [-80,80; -120,90; -60,90]';
mmDt = [2 2 2];
mmAnat = [1 1 1];
autoAlign = false;
showFigs = true;

if ~exist('b0FileName','var') | isempty(b0FileName)
    [f, p] = uigetfile({'*.nii.gz','NIFTI gz';'*.*','All files'}, 'Select the FSL S0 file...');
    if(isnumeric(f)) error('Need an S0 file to continue...'); end
    b0FileName = fullfile(p, f);
    disp(b0FileName);
end
b0 = niftiRead(b0FileName);
% Fix ill-specified quaternion xforms so that they do something reasonable.
if(all(b0.qto_ijk(1:3,4) == [0 0 0]'))
    % *** HACK! [38 69 28] is the ac for one normalized data set- maybe it
    % works for many?
    sz = size(b0.data);
    origin = round(sz(1:3)./2.*[0.95 1.1 0.9]);
    b0.qto_ijk(1:3,4) = origin'+0.5;
    b0.qto_xyz = inv(b0.qto_ijk);
end
b0.data = double(b0.data);
% Clip vals <0 (these should be junk for a b=0 image)
b0.data(b0.data<0) = 0;

if ~exist('t1FileName','var')
    [f, p] = uigetfile({'*.nii.gz','NIFTI gz';'*.hdr','Analyze files (*.hdr)';'*.*','All files'},...
        'Select the T1 file...', b0FileName);
    if(isnumeric(f))
        t1FileName = [];
    else
        t1FileName = fullfile(p, f);
        disp(t1FileName);
    end
end
if(~isempty(t1FileName))
    t1 = niftiRead(t1FileName);
    % Fix ill-specified quaternion xforms so that they do something reasonable.
    if(all(t1.qto_ijk(1:3,4) == [0 0 0]'))
        sz = size(t1.data);
        origin = round(sz(1:3)./2.*[0.95 1.1 0.9]);
        t1.qto_ijk(1:3,4) = origin'+0.5;
        t1.qto_xyz = inv(t1.qto_ijk);
    end
    t1.data = double(t1.data);
    t1.data(t1.data<0) = 0;
else
    t1 = b0;
end

[datapath,basename] = fileparts(b0FileName);
us = strfind(basename,'_');
basename = basename(1:us(end));

if(~exist('outPathName','var') | isempty(outPathName))
    outPathName = fullfile(datapath, [basename 'dt6.mat']);
end
if(exist(outPathName,'file') | exist([outPathName '.mat'],'file'))
  disp('output file exists- please rename...');
  [f,p] = uiputfile('*.mat', 'Select output file...', outPathName);
  if(isnumeric(f)) error('User cancelled.'); end
  outPathName = fullfile(p,f);
end

disp(['Data will be saved in ' outPathName '...']);

% *** TO DO: fix this- here we assume that the data use a NIFTI-style
% header and this it's quaternion xform is specified correctly.
t1.acpcXform = t1.qto_xyz;
b0.acpcXform = b0.qto_xyz;
% reslicing introduces a 1/2 voxel (1mm shift. We correct for that here.
b0.acpcXform(1:3,4) = b0.acpcXform(1:3,4)-mmDt'./2;

h = figure;
showFigure(h, t1, b0, bb, slice);
%set(h,'Position', [10, 50, 1000, 1000]);
set(h, 'PaperPositionMode', 'auto');
print(h, '-dpng', '-r90', [outPathName,'_headerAlign.png']);
if(~showFigs) close(h); end

if(autoAlign)
    disp('Coregistering (using spm2 tools)...');
    img = t1.data;
    img = mrAnatHistogramClip(img, 0.50, 0.995);
    VG.uint8 = uint8(round(img*255));
    VG.mat = t1.acpcXform;

    img = b0.data;
    img = mrAnatHistogramClip(img,0.40, 0.99);
    VF.uint8 = uint8(round(img*255));
    VF.mat = b0.acpcXform;
    p = defaults.coreg.estimate;
    % NOTE: there seems to be a consistent 1mm (1/2 of B0 voxel) translation
    % between the t1 and B0.
    transRot = spm_coreg(VG,VF,p);
    transRot(1:3) = transRot(1:3)+mmDt/2;
    b0.acpcXform = inv(VF.mat\spm_matrix(transRot(:)'));
    fig = figure;
    showFigure(fig, t1, b0, bb, [0,0,0], ['auto aligned']);
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, '-dpng', '-r90', [outPathName,'_autoAlign.png']);
end

% Now build and save the dt6 data
eigVal = zeros([size(b0.data) 3]);
eigVec = zeros([size(b0.data) 3 3]);
for(ii=1:3)
    tmp = niftiRead(fullfile(datapath, [basename 'L' num2str(ii) '.nii.gz']));
    eigVal(:,:,:,ii) = double(tmp.data);
end
for(ii=1:3)
    tmp = niftiRead(fullfile(datapath, [basename 'V' num2str(ii) '.nii.gz']));
    eigVec(:,:,:,:,ii) = double(tmp.data);
    eigVec(:,:,:,2,ii) = -eigVec(:,:,:,2,ii);
end

dt6 = dtiRebuildTensor(eigVec, eigVal);
clear eigVal eigVec;
%dt6_tmp = dtiLoadTensorElements(fullfile(fileparts(b0.baseFname), 'TensorElements.float.'));
%%dt6_tmp = permute(dt6_tmp,[2 1 3 4]);
%for(ii=1:6)
%    dt6(:,:,:,ii) = applyCannonicalXform(dt6_tmp(:,:,:,ii), b0.cannonical, b0.mmPerVox);
%end
%dt6 = permute(dt6,[2 1 3 4]);
%clear dt6_tmp;

% Reslice everything
disp('Interpolating tensors...');
%dt6A = dtiResliceTensorAffine(dt6, inv(b0.acpcXform), b0.cannonical_mmPerVox, bb, mmDt);
%dt6A = permute(dt6A,[2 1 3 4]);
dt6 = mrAnatResliceSpm(dt6, inv(b0.acpcXform), bb, mmDt, [7 7 7 0 0 0], showFigs);
dt6(isnan(dt6)) = 0;
% NOTE: we want to apply b0.acpcXform to the tensors, even though we
% resliced them with inv(b0.acpcXform). inv(b0.acpcXform) maps from
% the new space to the old- the correct mapping for the interpolation,
% since we interpolate by creating a grid in the new space and fill it by
% pulling data from the old space. But the tensor reorientation should be
% done using the old-to-new space mapping (b0.acpcXform).
rigidXform = dtiFiniteStrainDecompose(b0.acpcXform);
[t,r] = affineDecompose([rigidXform,[0 0 0]';[0 0 0 1]]);
if(all(all(rigidXform==eye(3))))
    disp('No PPD correction needed- rotation is zero.');
else
    fprintf('Applying PPD rotation [%0.4f %0.4f %0.4f]...\n',r);
    dt6 = dtiXformTensors(dt6, rigidXform);
end
%figure; imagesc(makeMontage(dt6_new(:,:,:,1))); axis equal; colormap gray

disp('Interpolating B0...');
[b0_img,newXform] = mrAnatResliceSpm(b0.data, inv(b0.acpcXform), bb, mmDt, [7 7 7 0 0 0], showFigs);
b0_img(b0_img<0) = 0;
b0_img(isnan(b0_img)) = 0;

% create and apply a brain mask to the dt6 data
brainMask = mrAnatHistogramClip(b0_img, 0.4, 0.99);
brainMask = brainMask > 0.1;
% [c,v] = mrAnatHistogramSmooth(b0_img,256,0.05);
% % derivative of the thresholded derivative gives us the locations where a
% % rising or falling trend begins. In general, we can just take the first
% % rising trend (ie. just after the background noise) to find the brain.
% % We then back off from that by 25% (an empirically determined heuristic).
% peakStart = find(diff(diff(c)>0)>0);
% thresh = v(peakStart(1)+2);
% thresh = thresh.*0.75;
% brainMask = b0_img > thresh;
brainMask = dtiCleanImageMask(brainMask, 9);
figure; imagesc(makeMontage(brainMask)); axis equal tight; colormap(gray);
title('Brain Mask (based on b=0 image)');
dt6(repmat(~brainMask, [1,1,1,6])) = 0;

disp('Interpolating T1...');
anat.img = mrAnatResliceSpm(t1.data, inv(t1.acpcXform), bb, mmAnat, [], showFigs);
anat.img(anat.img<0) = 0;
anat.img(isnan(anat.img)) = 0;
anat.img = int16(round(anat.img));

mmPerVox = mmDt;
notes = 'Built from FSL data';
b0 = int16(round(b0_img));
anat.mmPerVox = mmAnat;

origin = bb(1,[1,2,3])-mmDt./2;
xformToAnat = [diag(mmDt./mmAnat) [0 0 0]'; [0 0 0 1]];
xformToAcPc = [diag(mmDt) origin'; [0 0 0 1]]; %swapXY*[diag(mm) origin'; [0 0 0 1]];
anat.xformToAcPc = [diag(mmAnat) origin'; [0 0 0 1]];
% rp = t1.talairach.refPoints;
% % Why swap coords like this? Well, the real reason has to do with the
% % history of ComputeTalairach. We could figure this out in a more general
% % way using t1.talairach.refPoints.mat, which tells us how the coords were
% % transformed in ComputeTalairach. In the end, the following reordering
% % works for our data, since the pre-processing is consistent.
% mm = t1.cannonical_mmPerVox([2 3 1]);
anat.talScale.notes = ['Scale factors to go from subject mm to Talairach mm.' ...
                       'Eg. talCoord = anat.talScale.sac * imgCoord.' ...
                       'The scales are (in order) superior, inferior, left, right ' ...
                       'and anterior of AC, ac-to-pc and posterior of pc.'];
% anat.talScale.sac = 72./sqrt(sum(((rp.acXYZ-rp.sacXYZ).*mm).^2));
% anat.talScale.iac = 42./sqrt(sum(((rp.acXYZ-rp.iacXYZ).*mm).^2));
% anat.talScale.lac = 62./sqrt(sum(((rp.acXYZ-rp.lacXYZ).*mm).^2));
% anat.talScale.rac = 62./sqrt(sum(((rp.acXYZ-rp.racXYZ).*mm).^2));
% anat.talScale.aac = 68./sqrt(sum(((rp.acXYZ-rp.aacXYZ).*mm).^2));
% anat.talScale.acpc = 24./sqrt(sum(((rp.acXYZ-rp.pcXYZ).*mm).^2));
% % The PPC is referenced to the PC. It is at Talairach (0,-102,0) and the PC
% % is at (0,-24,0), so it is 78 mm beyond the PC.
% anat.talScale.ppc = 78./sqrt(sum(((rp.pcXYZ-rp.ppcXYZ).*mm).^2));
anat.talScale.sac = 1.0;
anat.talScale.iac = 1.0;
anat.talScale.lac = 1.0;
anat.talScale.rac = 1.0;
anat.talScale.aac = 1.0;
anat.talScale.acpc = 1.0;
anat.talScale.ppc = 1.0;

disp(['Saving to ' outPathName '...']);
l = license('inuse'); h = hostid;
created = ['Created at ' datestr(now,31) ' by ' l(1).user ' on ' h{1} '.'];
save(outPathName, 'dt6', 'mmPerVox', 'notes', 'xformToAnat', 'xformToAcPc', 'b0', 'anat', 'created');
if(nargout==0)
    clear dt6;
end
return;



function showFigure(fig, t1, b0, bb, slice, figName)
if(~exist('figName','var')) figName = 'Interpolated slices'; end
% Get X,Y and Z (L-R, A-P, S-I) slices from T1 and b0 volumes
[t1Xsl] = dtiGetSlice(t1.acpcXform,t1.data,3,slice(3),bb);
[t1Ysl] = dtiGetSlice(t1.acpcXform,t1.data,2,slice(2),bb);
[t1Zsl] = dtiGetSlice(t1.acpcXform,t1.data,1,slice(1),bb);
[b0Xsl] = dtiGetSlice(b0.acpcXform,b0.data,3,slice(3),bb);
[b0Ysl] = dtiGetSlice(b0.acpcXform,b0.data,2,slice(2),bb);
[b0Zsl] = dtiGetSlice(b0.acpcXform,b0.data,1,slice(1),bb);
% Max values for image scaling
t1mv = max([t1Xsl(:); t1Ysl(:); t1Zsl(:)])+0.000001;
b0mv = max([b0Xsl(:); b0Ysl(:); b0Zsl(:)])+0.000001;
% Create XxYx3 RGB images for each of the axis slices. The green and 
% blue channels are from the T1, the red channel is an average of T1 
% and b=0.
Xsl(:,:,1) = t1Xsl./t1mv.*.5 + b0Xsl./b0mv.*.5;
Xsl(:,:,2) = t1Xsl./t1mv.*.5; Xsl(:,:,3) = t1Xsl./t1mv.*.5;
Ysl(:,:,1) = t1Ysl./t1mv.*.5 + b0Ysl./b0mv.*.5;
Ysl(:,:,2) = t1Ysl./t1mv.*.5; Ysl(:,:,3) = t1Ysl./t1mv.*.5;
Zsl(:,:,1) = t1Zsl./t1mv.*.5 + b0Zsl./b0mv.*.5;
Zsl(:,:,2) = t1Zsl./t1mv.*.5; Zsl(:,:,3) = t1Zsl./t1mv.*.5;

% Show T1 slices
figure(fig); set(fig, 'NumberTitle', 'off', 'Name', figName);
figure(fig); subplot(3,3,1); imagesc(bb(:,1), bb(:,2), t1Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,2); imagesc(bb(:,3), bb(:,1), t1Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,3); imagesc(bb(:,3), bb(:,2), t1Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show b=0 slices
figure(fig); subplot(3,3,4); imagesc(bb(:,1), bb(:,2), b0Xsl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,5); imagesc(bb(:,3), bb(:,1), b0Ysl); 
colormap(gray); axis equal tight xy;
figure(fig); subplot(3,3,6); imagesc(bb(:,3), bb(:,2), b0Zsl); 
colormap(gray); axis equal tight xy; 
axis equal tight;

% Show combined slices
figure(fig); subplot(3,3,7); imagesc(bb(:,1), bb(:,2), Xsl); 
axis equal tight xy;
figure(fig); subplot(3,3,8); imagesc(bb(:,3), bb(:,1), Ysl); 
axis equal tight xy;
figure(fig); subplot(3,3,9); imagesc(bb(:,3), bb(:,2), Zsl); 
axis equal tight xy; 
axis equal tight;

return;
