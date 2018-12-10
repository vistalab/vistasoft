function dt6 = dtiMakeDt6FromFsl(b0FileName, t1FileName, outPathName, autoAlign)
%
% dt6 = dtiMakeDt6FromFsl([b0FileName], [t1FileName], [outPathName], [autoAlign=true])
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
% 2006.04.27 RFD: adapted it for the Phillips data at MUSC. The old version
% (customized for data from U Washington) is now saved as
% dtiMakeDt6FromFsl_UW.
% 2006.06.12 DLA: temporary workaround for a bug in niftiRead (ignoring
% the offset field of Analyze files.)
% 2006.11.28 RFD: reset default mmDt to [2 2 2] (was [1 1 1]), more
% stringent checking for crazy b0 qto xform matrices, brain mask is now
% computed and saved but not applied (consistent with the new dtiMakeDt6
% default behavior).

slice = [0,0,0]; % slice to display for checking coregistration
bb = [-80,80; -120,90; -60,90]';
mmDt = [2 2 2]; % 2006.11.28 RFD: changed from [1 1 1]
mmAnat = [1 1 1];
showFigs = true;
tensorInterpSpline = false;
if ~exist('autoAlign','var') | isempty(autoAlign)
    autoAlign = true;
end
applyDtBrainMask = false;
if ~exist('b0FileName','var') | isempty(b0FileName)
    [f, p] = uigetfile({'*.nii.gz','NIFTI gz';'*.*','All files'}, 'Select the FSL S0 file...');
    if(isnumeric(f)) error('Need an S0 file to continue...'); end
    b0FileName = fullfile(p, f);
    disp(b0FileName);
end
b0 = niftiRead(b0FileName);
% Fix ill-specified quaternion xforms so that they do something reasonable.
flipDti = 0;
flipVecs = [0 0 0];
sz = size(b0.data);
if(any(abs(b0.qto_ijk(1:3,4)) < [sz./10]') | any(abs(b0.qto_ijk(1:3,4))>sz'.*3))
    % *** HACK! [0.95 1.1 0.7] is near the ac for one data set
    if(det(b0.qto_ijk(1:3,1:3))<0)
        flipDti(1) = 1;
        b0.data = flipdim(b0.data,1);
    end
    origin = round(sz(1:3)./2.*[0.95 1.1 0.7]);
    b0.qto_ijk = affineBuild(origin'+0.5, [0 0 0], 1./b0.pixdim, [0 0 0]);
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
        autoAlign = false;
    else
        t1FileName = fullfile(p, f);
        disp(t1FileName);
    end
end
if(~isempty(t1FileName))
  if(strcmpi(t1FileName(end-1:end),'gz'))
    t1 = niftiRead(t1FileName);
  else
    % should just use niftiRead here, but there is a bug in 
    % niftiRead that causes it to ignore the offset in Analyze
    % format. So we use loadAnalyze here explicitly, as a temporary
    % fix.
    % - dla and rfd

    [t1.data,t1.pixdim,hdr] = loadAnalyze(t1FileName);
    origin = -hdr.mat(1:3,4);
    t1.qto_ijk = [diag(t1.pixdim),origin+0.5;[0 0 0 1]];
    t1.qto_xyz = inv(t1.qto_ijk);
    % t1 = niftiRead(t1FileName);
    % Fix ill-specified quaternion xforms so that they do something reasonable.
    if(all(t1.qto_ijk(1:3,4) == [0 0 0]'))
        sz = size(t1.data);
        origin = round(sz(1:3)./2.*[0.95 1.1 0.9]);
        t1.qto_ijk(1:3,4) = origin'+0.5;
        t1.qto_xyz = inv(t1.qto_ijk);
    end
  end
  t1.data = double(t1.data);
  t1.data(t1.data<0) = 0;
  t1.acpcXform = t1.qto_xyz;
else
    t1 = [];
end

[datapath,basename] = fileparts(b0FileName);
us = strfind(basename,'_');
basename = basename(1:us(end));

if(~exist('outPathName','var') | isempty(outPathName))
    outPathName = fullfile(datapath, [basename 'dt6.mat']);
    if(exist(outPathName,'file') | exist([outPathName '.mat'],'file'))
        disp('output file exists- please rename...');
        [f,p] = uiputfile('*.mat', 'Select output file...', outPathName);
        if(isnumeric(f)) error('User cancelled.'); end
        outPathName = fullfile(p,f);
    end
end

disp(['Data will be saved in ' outPathName '...']);

% *** TO DO: fix this- here we assume that the data use a NIFTI-style
% header and this it's quaternion xform is specified correctly.
b0.acpcXform = b0.qto_xyz;

h = figure;
if(showFigs & ~isempty(t1)) 
    dtiShowAlignFigure(h, t1, b0, bb, slice);
    %set(h,'Position', [10, 50, 1000, 1000]);
    set(h, 'PaperPositionMode', 'auto');
    print(h, '-dpng', '-r90', [outPathName,'_headerAlign.png']);
    close(h); 
end

if(autoAlign)
    spm_defaults;
    if(~exist('defaults','var')) global defaults; end
    disp('Coregistering (using spm tools)...');
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
    dtiShowAlignFigure(fig, t1, b0, bb, [0,0,0], ['auto aligned']);
    set(fig, 'PaperPositionMode', 'auto');
    print(fig, '-dpng', '-r90', [outPathName,'_autoAlign.png']);
end

% Now build and save the dt6 data
eigVal = zeros([size(b0.data) 3]);
eigVec = zeros([size(b0.data) 3 3]);
for(ii=1:3)
    tmp = niftiRead(fullfile(datapath, [basename 'L' num2str(ii) '.nii.gz']));
    if(flipDti) tmp.data = flipdim(tmp.data,1); end
    eigVal(:,:,:,ii) = double(tmp.data);
end
for(ii=1:3)
    tmp = niftiRead(fullfile(datapath, [basename 'V' num2str(ii) '.nii.gz']));
    if(flipDti) tmp.data = flipdim(tmp.data,1); end
    eigVec(:,:,:,:,ii) = double(tmp.data);
    if(any(flipVecs))
        flipThese = find(flipVecs);
        for(jj=flipThese)
            eigVec(:,:,:,jj,ii) = -eigVec(:,:,:,jj,ii);
        end
    end
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

if(autoAlign)
    % Reslice everything
    disp('Interpolating tensors...');
    %dt6A = dtiResliceTensorAffine(dt6, inv(b0.acpcXform), b0.cannonical_mmPerVox, bb, mmDt);
    %dt6A = permute(dt6A,[2 1 3 4]);
    if(tensorInterpSpline)
        dt6 = mrAnatResliceSpm(dt6, inv(b0.acpcXform), bb, mmDt, [7 7 7 0 0 0], showFigs);
    else
        dt6 = mrAnatResliceSpm(dt6, inv(b0.acpcXform), bb, mmDt, [1 1 1 0 0 0], showFigs);
    end
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
    mmPerVox = mmDt;
else
    b0_img = b0.data;
    mmPerVox = b0.pixdim;
    xformToAcPc = b0.acpcXform;
end
b0_img(b0_img<0) = 0;
b0_img(isnan(b0_img)) = 0;
% create and apply a brain mask to the dt6 data
dtBrainMask = mrAnatHistogramClip(b0_img, 0.4, 0.99);
dtBrainMask = dtBrainMask > 0.1;
% [c,v] = mrAnatHistogramSmooth(b0_img,256,0.05);
% % derivative of the thresholded derivative gives us the locations where a
% % rising or falling trend begins. In general, we can just take the first
% % rising trend (ie. just after the background noise) to find the brain.
% % We then back off from that by 25% (an empirically determined heuristic).
% peakStart = find(diff(diff(c)>0)>0);
% thresh = v(peakStart(1)+2);
% thresh = thresh.*0.75;
% brainMask = b0_img > thresh;
dtBrainMask = dtiCleanImageMask(dtBrainMask, 9);
if(applyDtBrainMask)
    dt6(repmat(~dtBrainMask, [1,1,1,6])) = 0;
    figure; imagesc(makeMontage(dtBrainMask)); axis equal tight; colormap(gray);
    title('Brain Mask (based on b=0 image)');
end

if(~isempty(t1))
    if(autoAlign)
        disp('Interpolating T1...');
        anat.img = mrAnatResliceSpm(t1.data, inv(t1.acpcXform), bb, mmAnat, [], showFigs);
        anat.mmPerVox = mmAnat;
        origin = bb(1,[1,2,3])-mmDt./2;
        xformToAcPc = [diag(mmDt) origin'; [0 0 0 1]]; %swapXY*[diag(mm) origin'; [0 0 0 1]];
        anat.xformToAcPc = [diag(mmAnat) origin'; [0 0 0 1]];
    else
        anat.img = t1.data;
        anat.mmPerVox = t1.pixdim;
        anat.xformToAcPc = t1.acpcXform;
    end
    anat.img(anat.img<0) = 0;
    anat.img(isnan(anat.img)) = 0;
    % Crude test for an efficient storage class. Most data are either int16 to
    % begin with values generally above 100, or are floats scaled to [0,1].
    if(max(anat.img(:))>=100)
        anat.img = int16(round(anat.img));
    else
        anat.img = single(anat.img);
    end
end

notes = 'Built from FSL data';
if(max(b0_img(:))>=100)
    b0 = int16(round(b0_img));
else
    b0 = single(b0_img);
end

disp(['Saving to ' outPathName '...']);
l = license('inuse'); %h = hostid;
created = ['Created at ' datestr(now,31) ' by ' l(1).user  '.'];
if(~isempty(t1))
    save(outPathName, 'dt6', 'mmPerVox', 'notes', 'xformToAcPc', 'b0', 'dtBrainMask', 'anat', 'created');
else
    save(outPathName, 'dt6', 'mmPerVox', 'notes', 'xformToAcPc', 'b0', 'dtBrainMask', 'created');
end
if(nargout==0)
    clear dt6;
end
return;


