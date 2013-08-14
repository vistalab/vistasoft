function dtiRawEddyCorrect(dwRaw, mnB0, outEddyCorrectXform)
%
% dtiRawEddyCorrect([dwRaw=uigetfile], [mnB0=uigetfile], [outEddyCorrectXform])
%
% Aligns each raw DW image in dwRaw (NIFTI format) to the mean
% b=0 image, saving all the resulting xforms in outEddyCorrectXform.
%
% HISTORY:
% 2007.04.23 RFD: wrote it.

% Initialize SPM default params
spm_defaults; global defaults;
estParams = defaults.coreg.estimate;

%% Load the raw DW data (in NIFTI format)
if(~exist('dwRaw','var')|isempty(dwRaw))
    [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the raw DW NIFTI dataset...');
    if(isnumeric(f)) error('User cancelled.'); end
    dwRaw = fullfile(p,f);
end
if(ischar(dwRaw))
    % dwRaw can be a path to the file or the file itself
    [dataDir,inBaseName] = fileparts(dwRaw);
else
    [dataDir,inBaseName] = fileparts(dwRaw.fname);
end
[junk,inBaseName,junk] = fileparts(inBaseName);
if(isempty(dataDir)) dataDir = pwd; end

% Load the b0 data (in NIFTI format)
if(~exist('mnB0','var')|isempty(mnB0))
   mnB0 = fullfile(dataDir, [inBaseName '_b0.nii.gz']);
   [f,p] = uigetfile({'*.nii.gz;*.nii';'*.*'}, 'Select the mean b0 NIFTI dataset...',mnB0);
   if(isnumeric(f)) error('User cancelled.'); end
   mnB0 = fullfile(p,f);
end
if(ischar(mnB0))
    disp(['Loading b0 data ' mnB0 '...']);
    mnB0 = niftiRead(mnB0);
end

if(~exist('outEddyCorrectXform','var')|isempty(outEddyCorrectXform))
    outEddyCorrectXform = fullfile(dataDir,[inBaseName 'EcXform']);
end

if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end

nvols = size(dwRaw.data,4);
dtMm = dwRaw.pixdim(1:3);

%% Eddy correction (will also correct for motion)
% Compute an affine xform to align each DW image to the mean B0
% image.
% Affine (12-params)
estParams.params = [0 0 0 0 0 0 1 1 1 0 0 0];
estParams.sep = [2];
target.uint8 = uint8(round(mrAnatHistogramClip(double(mnB0.data),0.4,0.99)*255));
target.mat = [diag(dtMm), [-[size(target.uint8)/2].*dtMm]'; 0 0 0 1];
source.mat = target.mat;
for(ii=1:nvols)
    fprintf('Aligning vol %d of %d to mean b=0 image', ii, nvols);
    if(ii>2)
        % Skip the first since it's usually the reference.
        estRemain = mean(et(2:end))*(nvols-ii+1)./60;
        if(estRemain>90) estRemain = estRemain./60; estUnits = 'hours';
        else estUnits = 'minutes'; end
        fprintf(' (previous iteration took %0.1f secs; %0.1f %s remaining)...\n',et(ii-1),estRemain,estUnits);
    else
        fprintf('\n');
    end
    tic;
    im = double(dwRaw.data(:,:,:,ii));
    source.uint8 = uint8(round(mrAnatHistogramClip(im,0.4,0.99)*255));
    msg = evalc('xformParams = spm_coreg(source,target,estParams);');
    xform{ii} = inv(target.mat)*spm_matrix(xformParams)*source.mat;
    et(ii) = toc;
end
disp(['Saving eddy/motion correction transforms to ' outEddyCorrectXform '...']);
disp('These transforms map voxels in each of the volumes to the reference image (usually the mean b=0).');
save(outEddyCorrectXform, 'xform');
fn = [outEddyCorrectXform '.txt'];
dlmwrite(fn,xform{1},'delimiter',' ','precision',6);
for(ii=2:length(xform))
    dlmwrite(fn,xform{ii},'delimiter',' ','roffset',1,'-append','precision',6);
end

return;
