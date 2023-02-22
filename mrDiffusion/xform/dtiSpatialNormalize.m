function dtiSpatialNormalize(dt6FileName, templateName, outDirName, useBrainMask, useB0) 
%
% dtiSpatialNormalize([dt6FileName=uiget], [templateName='MNI'],
%                     [outDirName=inName_templateName], 
%                     [useBrainMaskFlag=false], [useB0Flag=false])
%
% Compute spatial normalization for a single subject and save a
% spatially-normalized copy of the data. Now works with the new
% NIFTI-based dt6 format (should work on old data too). 
%
% To normalize a mrDiffusion dataset, try running dtiSpatialNormalize. If
% you don't enter a specific dt6 filename, it will prompt you for a
% dt6 file. It will save a normalized copy of the data in a
% directory with the same name as the one containing the dt6 file,
% but with '_templateName' appended on the end. It will also save a
% png image in there that is a montage showing the normalized PDD
% map overlaid on the MNI t1. This is useful for checking the results. 
%
% 2007.10.30 RFD: revamped this script, cleaning up much code in the
% process.
% 2007.11.19 RFD: turned this into a proper function and moved it
% to the xform dir.

if(~exist('dt6FileName','var'))
  dt6FileName = ''; 
end
if(~exist('useB0','var')||isempty(useB0))
  useB0 = false;
end
if(~exist('useBrainMask','var')||isempty(useBrainMask))
  useBrainMask = false;
end
if(~exist('templateName','var')||isempty(templateName))
  templateName = 'MNI';
end

switch templateName
 case {'MNI','SIRL54'}
  templateDir = fullfile(fileparts(which('mrDiffusion.m')),'templates');
  if(useB0)
	template = fullfile(templateDir, [templateName '_EPI']);
  else
	template = fullfile(templateDir, [templateName '_T1']);
  end
  if(useBrainMask)
	template = [template '_brain'];
  end
  template = [template '.nii.gz'];
 otherwise
  template = templateName;
  [junk,templateName] = fileparts(template);
end

[dt,t1] = dtiLoadDt6(dt6FileName,false);

if(~exist('outDirName','var')||isempty(outDirName))
  outDirName = [fileparts(dt.dataFile) '_' templateName];
end
spm_defaults; global defaults; defaults.analyze.flip = 0;
params = defaults.normalise.estimate;

if(useB0)
    desc = [templateName ' normalized using b0'];
    im = mrAnatHistogramClip(double(dt.b0),0.4,0.98);
    xf = dt.xformToAcpc;
	if(useBrainMask)
	  im(~dt.brainMask) = 0;
	  desc = [desc ' (masked)'];
	end
else
    desc = [templateName ' normalized using T1'];
    im = mrAnatHistogramClip(double(t1.img),0.4,0.98);
    xf = t1.xformToAcpc;
	if(useBrainMask)
	  im(~t1.brainMask) = 0;
	  desc = [desc ' (masked)'];
	end
end

disp(['Normalizing ' dt6FileName ' to ' template '...']);
sn = mrAnatComputeSpmSpatialNorm(im, xf, template, params);

[dt_sn,t1_sn] = dtiSpmDeformer(dt,sn,t1);

t1 = niftiGetStruct(single(t1_sn.img), t1_sn.xformToAcpc, [], desc, 't1');
b0 = niftiGetStruct(single(dt_sn.b0), dt_sn.xformToAcpc, [], desc, 'b=0');
bm = niftiGetStruct(uint8(dt_sn.brainMask), dt_sn.xformToAcpc, [], desc, 'dtBrainMask');
sz = size(dt_sn.dt6);
niftiDt6 = reshape(dt_sn.dt6(:,:,:,[1 4 2 5 6 3]),[sz(1:3),1,sz(4)]);
tensors = niftiGetStruct(niftiDt6, dt_sn.xformToAcpc, [], desc, 'DTI');

% Load the MNI to check the normalization results:
mni = niftiRead(fullfile(templateDir, 'MNI_T1.nii.gz'));
[pddT1,acpcToImXform,mm] = dtiRawCheckTensors(tensors, mni, bm);
sl = 6:2:size(mni.data,3)-2;
imgRgb = makeMontage3(flipdim(permute(pddT1,[2 1 3 4]),1), sl, mni.pixdim(1), 0, [], [], -1);
%figure; image(imgRgb);

% To save the results:
[fullParentDir, dataDir] = fileparts(outDirName);
files.b0 = fullfile(dataDir,'bin','b0.nii.gz');
files.brainMask = fullfile(dataDir,'bin','brainMask.nii.gz');
files.tensors = fullfile(dataDir,'bin','tensors.nii.gz');
files.t1 = fullfile(dataDir,'t1.nii.gz');
mkdir(outDirName);
mkdir(fullfile(outDirName,'bin'));
b0.fname = fullfile(fullParentDir,files.b0);
tensors.fname = fullfile(fullParentDir,files.tensors);
bm.fname = fullfile(fullParentDir,files.brainMask);
t1.fname = fullfile(fullParentDir,files.t1);
writeFileNifti(b0);
writeFileNifti(tensors);
writeFileNifti(bm);
writeFileNifti(t1);
adcUnits = dt_sn.adcUnits;
params.buildDate = datestr(now,'yyyy-mm-dd HH:MM');
l = license('inuse');
params.buildId = sprintf('%s on Matlab R%s (%s)',l(1).user,version('-release'),computer);
params.sourceData = dt_sn.dataFile;
save(fullfile(outDirName,'dt6'),'adcUnits','params','files');
imwrite(imgRgb,fullfile(outDirName,'pddT1.png'));

return;




bd = '/biac3/wandell4/data/reading_longitude/dti_y4/';
inDir = 'dti06_smooth2';

d = dir(fullfile(bd,'*0*'));
n = 0;
for(ii=1:length(d))
  tmp = fullfile(bd,d(ii).name,inDir,'dt6.mat');
  if(exist(tmp,'file'))
	n = n+1;
    sc{n} = d(ii).name;
	fn{n} = tmp;
  end
end

for(ii=1:length(fn))
  disp(['Processing ' sc{ii} '...']);
  dtiRawFixDt6File(fn{ii});
  dtiSpatialNormalize(fn{ii}, 'SIRL54', [], true);
end
