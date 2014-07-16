function [xform, t1, mnB0] = dtiRawWarpT1ToDwi(t1, mnB0)
% 
% xform = dtiRawWarpT1ToDwi(t1, mnB0)
%
% Estimates the 14-parameter motion and eddy-current deformation to warp
% a t1 image to the (distorted) dwi space. Uses the algorithm described in:
%
%   Rohde, Barnett, Basser, Marenco and Pierpaoli (2004). Comprehensive
%   Approach for Correction of Motion and Distortion in Diffusion-Weighted
%   MRI. MRM 51:103-114.
%
% For example:
%  [xform, t1, b0] = dtiRawWarpT1ToDwi('t1/t1.nii.gz', 'dti06/bin/b0.nii.gz');
%  bb = mrAnatXformCoords(b0.qto_xyz,[1 1 1; size(b0.data)]);
%  outMm = b0.pixdim(1:3);
%  xform.inMat = t1.qto_ijk;
%  [im,newXform] = mrAnatResliceSpm(mrAnatHistogramClip(double(t1.data),0.4,0.99), xform, bb, outMm);
%  im(isnan(im)|im<0) = 0; im(im>1) = 1;
%  showMontage(im);
%  ni = niftiGetStruct(int16(im*double(intmax('int16'))), newXform);
%  ni.fname = fullfile(fileparts(mnB0.fname),'t1.nii.gz');
%  writeFileNifti(ni);
%
%
% HISTORY:
%
% 2008.12.31 RFD: wrote it

%% PREP ARGUMENTS

% Load the t1 (in NIFTI format)
if(~exist('t1','var')||isempty(t1))
  [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the t1 NIFTI image...');
  if(isnumeric(f)) error('User cancelled.'); end
  t1 = fullfile(p,f);
end
if(ischar(t1))
  % t1 can be a path to the file or the file itself
  [dataDir,inBaseName] = fileparts(t1);
else
  [dataDir,inBaseName] = fileparts(t1.fname);
end
[junk,inBaseName,junk] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end

% Load the b0 data (in NIFTI format)
if(~exist('mnB0','var')||isempty(mnB0))
  mnB0 = fullfile(dataDir, [inBaseName '_b0.nii.gz']);
  [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the mean b0 NIFTI dataset...',mnB0);
  if(isnumeric(f)) error('User cancelled.'); end
  mnB0 = fullfile(p,f);
end
if(ischar(mnB0))
  disp(['Loading b0 data ' mnB0 '...']);
  mnB0 = niftiRead(mnB0);
end

% Check output file
if(~exist('outXform','var')||isempty(outXform))
  outXform = fullfile(dataDir,[inBaseName '_dwiXform']);
end

if(ischar(t1))
  disp(['Loading raw data ' t1 '...']);
  t1 = niftiRead(t1);
end

dtMm = mnB0.pixdim(1:3);
% We hope that the phase-encoding dir is set correctly in the NIFTI header!
phaseDir = mnB0.phase_dim; % 'e' in the Rohde paper
if(phaseDir==0)
  disp('NOTE: phase_dim in NIFTI header appears to have been set incorrectly- setting to 2.');
  phaseDir = 2;
end

bb = mrAnatXformCoords(mnB0.qto_xyz,[1 1 1; size(mnB0.data)]);
t1Mm = t1.pixdim(1:3);

% Set-up rigid-body alignment for motion correction
% Initialize SPM default params
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;
estParams.params = [0 0 0 0 0 0];
estParams.cost_fun = 'nmi';
estParams.fwhm = [7 7];
% Multiresolution search control params. Specifies the histogram sampling
% density, in mm. Try [8 4], [6 3], [4 2]?
estParams.sep = [4 2];

targetNoBlur.uint8 = uint8(round(mrAnatHistogramClip(double(mnB0.data),0.4,0.99)*255));
targetNoBlur.mat = mnB0.qto_xyz;

% Registration involves finding the coordinate transform (f_alpha) for each
% image volume (alpha) that transforms the target coordinates x into the
% source coordinates x_alpha. (We map target to source because for
% interpolation, we need to know from where in the source image we should
% pull the data to fill each voxel in the target image. Ie., for each
% target image voxel, we'll draw data from a point in the source image.)
%
tol = [2e-2 2e-2 2e-2, 1e-3 1e-3 1e-3, 3e-4 3e-4 3e-4, 1e-4 1e-4 1e-4 4e-5 2e-5];
% resample t1 to dwi space
[srcIm,srcMat] = mrAnatResliceSpm(mrAnatHistogramClip(double(t1.data),0.4,0.99), t1.qto_ijk, bb, dtMm, [1 1 1 0 0 0], 0);
srcIm = uint8(round(srcIm*255));
xform.phaseDir = phaseDir;
% Compute Rohde deformation
mc = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
startDirs = diag(tol*10);
for(sr=1:numel(estParams.sep))
	fprintf('Warping resolution level %d of %d)\n',sr,numel(estParams.sep));
    % Blur target image given the specified sampling densities
    fwhm = sqrt(max([1 1 1]*estParams.sep(sr)^2 - dtMm.^2, [0 0 0]))./dtMm;
    target.uint8 = mrAnatSmoothUint8(targetNoBlur.uint8,fwhm);
    srcImBlur = mrAnatSmoothUint8(srcIm,fwhm);
    sd = estParams.sep(sr)./dtMm;
    % % Initialize the error function- it will cache the srcImg and
    % % sample points (x) to save a little time.
    % dtiRawRohdeEddyError(mc, phaseDir, srcImBlur, target.uint8, sd);
	[mc,f] = spm_powell(mc(:), startDirs, tol, 'dtiRawRohdeEddyError', phaseDir, srcImBlur, target.uint8, sd);
end
xform.ecParams = mc';

disp(['Saving t1 warp transform to ' outXform '...']);
save(outXform, 'xform');
% Might switch to a simple text-format output?
% fn = [outEddyCorrectXform '.txt'];
% dlmwrite(fn,xform{1},'delimiter',' ','precision',6);
% for(ii=2:length(xform))
%     dlmwrite(fn,xform{ii},'delimiter',' ','roffset',1,'-append','precision',6);
% end

%b = uint8(im*255+0.5); r = b/2+targetNoBlur.uint8/2; g = r; makeMontage3(r,g,b);

return;

bd =  '/biac3/wandell4/data/reading_longitude/dti_y1234/';
%subs = {'mho040625','mho050528','mho060527','mho070519'};
subs = {'at040918','at051008','at060825','at070815'};


% Align and resamble class from y1 to other years
r = niftiRead(fullfile(bd,subs{1},'t1','t1.nii.gz'));
c = niftiRead(fullfile(bd,subs{1},'t1','t1_class.nii.gz'));
for(ii=2:numel(subs))
    a = niftiRead(fullfile(bd,subs{ii},'t1','t1.nii.gz'));
    sz = size(a.data);
    xform =  mrAnatRegister(double(r.data),double(a.data),[],[],true);
    bb = [1 1 1; sz];
    %newSrcIm =  mrAnatResliceSpm(double(r.data), xform, bb, [1 1 1], [1 1 1 0 0 0], false);
    cVals = uint8(unique(c.data(:)));
    cVals = cVals(cVals>0);
    cNew = niftiGetStruct(zeros(sz,'uint8'), c.qto_xyz, c.scl_slope, c.descrip, c.intent_name, c.intent_code);
    cNew.fname = fullfile(bd,subs{ii},'t1','t1_class.nii.gz');
    for(jj=1:numel(cVals))
        tmp = mrAnatResliceSpm(double(c.data==cVals(jj)), xform, bb, [1 1 1], [1 1 1 0 0 0], false);
        cNew.data(tmp>=0.5) = cVals(jj);
    end
    writeFileNifti(cNew);
end


for(ii=1:numel(subs))
    % Clean up the classification and add in the sub-cortical gray
    scgNi = mrGrayConvertFirstToClass(fullfile(bd,subs{ii},'t1','first','t1_sgm_all_th4_first.nii.gz'), false, []);
    l = mrGrayGetLabels;
    c = niftiRead(fullfile(bd,subs{ii},'t1','t1_class.nii.gz'));
    bm = niftiRead(fullfile(bd,subs{ii},'t1','t1_mask.nii.gz'));
    c.data(~bm.data) = 0;
    % Add a perimeter of CSF to ensure that the brain is encased in CSF.
    perim = imdilate(bm.data>0,strel('disk',5));
    perim = perim&bm.data==0;
    m = scgNi.data>0;
    c.data(m) = scgNi.data(m);
    c.data(perim) = l.CSF;
    movefile(fullfile(bd,subs{ii},'t1','t1_class.nii.gz'),fullfile(bd,subs{ii},'t1','t1_class_OLD.nii.gz'));
    writeFileNifti(c);
end

%%
% To generate a fascTrack seg image:
%
bd =  '/biac3/wandell4/data/reading_longitude/dti_y1234/';
subs = {'at040918','at051008','at060825','at070815'};
ip = [1 1 1 0 0 0];
for(ii=1:numel(subs))
    cd(fullfile(bd,subs{ii}));
    % Generate a simple seg file for FascTrack.
    t1 = niftiRead('t1/t1.nii.gz');
    t1.data = double(t1.data);
    bm = niftiRead('t1/t1_mask.nii.gz');
    bm.data = logical(bm.data);
    b0 = niftiRead('dti06/bin/b0.nii.gz');
    b0.data = double(b0.data);
    % unwarp using skull-stripped t1
    t1.data(~bm.data) = 0;
    [xform] = dtiRawWarpT1ToDwi(t1, b0);
    %load('t1/t1_dwiXform.mat');
    bb = mrAnatXformCoords(b0.qto_xyz,[1 1 1; size(b0.data)]);
    outMm = b0.pixdim(1:3);
    % FIX ME: reslicing twice works better- but we shold be able to make it
    % work in one go.
    t1Im = mrAnatResliceSpm(mrAnatHistogramClip(double(t1.data),0.4,0.99), t1.qto_ijk, bb, outMm, ip, 0);
    xform.inMat = b0.qto_ijk;
    [im,newXform] = mrAnatResliceSpm(t1Im, xform, bb, outMm, ip, 0);
    %xform.inMat = t1.qto_ijk;
    %[im,newXform] = mrAnatResliceSpm(mrAnatHistogramClip(double(t1.data),0.4,0.99), xform, bb, outMm, ip, 0);
	im(isnan(im)|im<0) = 0; im(im>1) = 1;
    showMontage(im);
	ni = niftiGetStruct(int16(im*double(intmax('int16'))), newXform);
	ni.fname = 'dti06/bin/t1.nii.gz';
	writeFileNifti(ni);
    
    l = mrGrayGetLabels;
    c = niftiRead('t1/t1_class.nii.gz');
    c.data = double(c.data);
    bm = niftiRead('t1/t1_mask.nii.gz');
    %disp('Growing Gray...');
    %cg = mrgSaveClassWithGray(4, c, []);
    % clear anything outside the brain mask
    disp('Clearing ~brainMask...');
    c.data(~bm.data) = 0;
    disp('Loading FIRST data...');
    % We want ventricles treated as wm, but nothing else
    scgNi = niftiRead('t1/first/t1_sgm_all_th4_first.nii.gz');
    disp('Labeling ventricles as CSF...');
    csf = any(scgNi.data(:,:,:,2:end)==4|scgNi.data(:,:,:,2:end)==104|scgNi.data(:,:,:,2:end)==43|scgNi.data(:,:,:,2:end)==143,4);
    csf = mrAnatResliceSpm(double(csf), t1.qto_ijk, bb, outMm, ip, 0);
    csf = mrAnatResliceSpm(double(csf), xform, bb, outMm, ip, 0);
    csf = csf >= 0.5;
    wm = mrAnatResliceSpm(double(c.data==l.leftWhite|c.data==l.rightWhite), t1.qto_ijk, bb, outMm, ip, 0);
    wm = mrAnatResliceSpm(wm, xform, bb, outMm, ip, 0);
    %gm = mrAnatResliceSpm(double(cg.data==l.leftGray|cg.data==l.rightGray|cg.data==l.subCorticalGM), t1.qto_ijk, bb, outMm, ip, 0);
    %gm = mrAnatResliceSpm(double(gm), xform, bb, outMm, ip, 0); gm=gm>=0.5;
    wm = wm>=0.5;
    gm = imdilate(wm,strel('disk',3)) & ~wm & ~csf;
    seg = niftiGetStruct(zeros(size(b0.data),'uint8'), b0.qto_xyz);
    seg.fname = 'dti06/bin/seg.nii.gz';
    seg.data(csf | wm) = 1;
    seg.data(gm) = 2;
    writeFileNifti(seg);
end


