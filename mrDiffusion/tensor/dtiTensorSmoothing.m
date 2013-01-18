function dtiTensorSmoothing(dt6File, rawF, iter, outDir)
%
% dtiTensorSmoothing([dt6File=uigetfile], [rawF=uigetfile], [iter=2], [outDir='ZZZ_smooth[iter]'])
%
% Convenient wrapper around dtiRawSmooth. Use this function to do
% tensor-based smoothing of diffusion-weighted data in the
% mrDiffusion dt6 format. Be sure to pass in the aligned, eddy-current
% corrected file for rawF.
%
% HISTORY:
% 2007.11.08 RFD: wrote it.
%

if(~exist('dt6File','var')||isempty(dt6File))
   [f,p] = uigetfile({'*.mat';'*.*'}, 'Select the unsmoothed dt6 file...');
   if(isnumeric(f)) error('User cancelled.'); end
   dt6File = fullfile(p,f);
end
inDir = fileparts(dt6File);
if(~exist('rawF','var')||isempty(rawF))
   [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the aligned, eddy-currect corrected raw DW NIFTI dataset...');
   if(isnumeric(f)) error('User cancelled.'); end
   f = f(1:strfind(f,'.nii')-1);
   rawF = fullfile(p,f);
end
if(~exist('iter','var')||isempty(iter))
  iter = 2;
end
if(~exist('outDir','var')||isempty(outDir))
  outDir = sprintf('%s_smooth%d',inDir,iter); 
end
[dw,xform,X,brainMask] = dtiRawSmooth([rawF '.nii.gz'],[rawF '.bvecs'],[rawF '.bvals'],iter);

%dtiWriteNiftiWrapper(dw, xform, sprintf('%s_smooth%d.nii.gz',rawF,iter), 1, [rawF ' tensor-smoothed'], ['DWI smoothed']);

disp('Finished smoothing- fitting tensors to smoothed data...');
[dt6,pdd] = dtiFitTensor(dw,X,[],[],brainMask);
b0 = exp(dt6(:,:,:,1));
dt6 = dt6(:,:,:,[2:7]);

disp('Saving smoothed tensor maps...');
if(~exist(outDir,'dir')) 
  mkdir(outDir);
end
if(~exist(fullfile(outDir,'bin'),'dir'))
  mkdir(outDir,'bin');
end
dt6 = dt6(:,:,:,[1 4 2 5 6 3]);
sz = size(dt6);
dt6 = reshape(dt6,[sz(1:3),1,sz(4)]);
desc = sprintf('tensor-smoothed (iter=%d) on %s',iter,datestr(now,'yyyy-mm-dd HH:MM'));
fname = fullfile(outDir,'bin','tensors.nii.gz');
dtiWriteNiftiWrapper(dt6, xform, fname, 1, desc, ['DTI']);
fname = fullfile(outDir,'bin','b0.nii.gz');
dtiWriteNiftiWrapper(int16(round(b0)), xform, fname, 1, desc, 'b0')
copyfile(fullfile(inDir,'bin','brainMask.nii.gz'),fullfile(outDir,'bin','brainMask.nii.gz'));
copyfile(fullfile(inDir,'dt6.mat'),fullfile(outDir,'dt6.mat'));
return;



bd = '/biac3/wandell4/data/reading_longitude/dti_y1/';
iter = 2;
inDir = 'dti06';
inRaw = 'dti_g13_b800_aligned';
outDir = sprintf('%s_smooth%d',inDir,iter);

d = dir(fullfile(bd,'*0*'));
for(ii=1:length(d))
    s{ii} = fullfile(bd,d(ii).name);
end

for(ii=36:length(s))
  rawF = fullfile(s{ii},'raw',inRaw);
  if(~exist([rawF '.nii.gz'],'file'))
	disp(['skipping ' s{ii} '...']);
	continue;
  end
  out = fullfile(s{ii},outDir);
  dtiTensorSmoothing(rawF, iter, out);
  copyfile(fullfile(s{ii},inDir,'bin','brainMask.nii.gz'),fullfile(out,'bin','brainMask.nii.gz'));
  copyfile(fullfile(s{ii},inDir,'dt6.mat'),fullfile(out,'dt6.mat'));
end
