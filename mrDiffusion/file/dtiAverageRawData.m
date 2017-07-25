function [imVol, mmPerVox, gradDirs, bVals, xformToCannonical] = dtiAverageRawData(firstDataFile, gradsFile)
% Intelligent averaging of diffusion-weighted images.
%
% [imVol, mmPerVox, gradDirs, bVals, xformToCannonical] = dtiAverageRawData(firstDataFile, gradsFile);
%
% Loads a whole directory of raw image files and combines them according to
% the gradient direction information in gradsFile. All repeated
% measurements are averaged. If coreg is true (default), it will also try
% to align each b>0 image to the b=0 image using a 12-parameter
% mutual-information algorithm (from SPM2). This should remove much of the
% eddy-current distortion.
%
% Also returns the xform that will rotate the images into our cannonical
% orientation (as close to axial as possible- see
% computeCannonicalXformFromIfile).
%
% TODO:
% * coreg should also do motion correction. To implement this, we need to
% do the coregistration step before we combine the repeated measurements.
% Of course, we should also correct the gradDirs for non-trivial motion.
%
%
% HISTORY:
% 2005.05.25: RFD (bob@sirl.stanford.edu) wrote it.
%

if(~exist('gradsFile','var')|isempty(gradsFile))
    % We could also try to infer the file based on info in the dicom
    % header.
    if(isunix)
      default = '/usr/local/dti/diffusion_grads/dwepi.13.grads';
    else
      default = pwd;
    end
    [f,p] = uigetfile({'*.grads';'*.*'},'Select dwepi grads file...',default);
    if(isequal(f,0)||isequal(p,0))
        error('User cancelled.');
    end
    gradsFile = fullfile(p,f);
end
if(~exist('firstDataFile','var')|isempty(firstDataFile))
    [f,p] = uigetfile({'*.dcm';'*.*'},'Select the first data file...');
    if(isequal(f,0)||isequal(p,0))
        error('User cancelled.');
    end
    firstDataFile = fullfile(p,f);
end

% Flag to turn on MI-based coregistration (eddy-current correction)
if(~exist('coreg','var')|isempty(coreg))
    coreg = false;
end

gradDirs = dlmread(gradsFile);
scannerToPhysXform = computeXformFromIfile(firstDataFile);
[xformToCannonical, baseName, mmPerVox, imDim, notes, sliceSkip] = computeCannonicalXformFromIfile(firstDataFile);
% *** TODO: may want to include im_hdr.scanspacing!
%mmPerVox(3) = mmPerVox(3)+sliceSkip;

% *** TODO: We assume that all non-zero b-vals are the same
hdr = dicominfo(firstDataFile);
bVals = hdr.Private_0019_10b0;

% HACK! TO deal with our interleaved data:
imDim(3) = imDim(3)*2;

[dataDir,f,ext] = fileparts(firstDataFile);
allFiles = dir(fullfile(dataDir, ['*' ext]));
nDirs = size(gradDirs,1);
nSlices = imDim(3);
filesPerRep = nDirs*nSlices;
nReps = length(allFiles)/filesPerRep;
if(nReps~=round(nReps))
    error('Non-integer number of repeats. Something is funky- refusing to go on...');
end

% TO DO: 
% * motion correction/outlier rejection
%
disp('Loading all the data files...');
imVol = zeros([imDim nDirs]);
for(d=1:nDirs)
  for(n=1:nReps)
    fn = [[1:nSlices]+(d-1)*nSlices+((n-1)*filesPerRep)];
    for s = 1:nSlices;
      curName = sprintf('I%04d.dcm', fn(s));
      tmpImg = readRawImage(fullfile(dataDir,curName), 0, nPix(1:2), 'b');
      imVol(:,:,s,d) = imVol(:,:,s,d)+double(tmpImg);
    end
  end
  %tmpIm = makeCubeIfiles(dataDir, nPix(1:2), fileNums);
end
imVol = imVol./nReps;

disp('Merging duplicate directions...');
% Merge duplicates
[gDirs,inds] = unique(gradDirs,'rows');
% undo unique's sorting
gDirs = gradDirs(sort(inds),:);
nDirs = size(gDirs,1);
junk= [];
for(ii=1:nDirs)
  dups = gDirs(ii,1)==gradDirs(:,1)&gDirs(ii,2)==gradDirs(:,2)& ...
         gDirs(ii,3)==gradDirs(:,3);
  dups = find(dups);
  if(length(dups)>1)
    imVol(:,:,:,dups(1)) = mean(imVol(:,:,:,dups),4);
    junk = [junk dups(2:end)];
  end
end
imVol(:,:,:,junk) = [];

if(coreg)
  disp('Coregistering...');
  % NOTE: The following MI-based image registration tries to
  % coregister each direction map to the b0. It doen't seem to do
  % anything bad, but isn't particularly effective at removing the
  % eddy-current distortion. I guess it's not a 3d affine xform?
  % But, if we ran it on the individual images before averaging, it
  % would probably be a good way to remove motion.
  b0 = imVol(:,:,:,1);
  b0 = uint8(mrAnatHistogramClip(b0, 0.4, 0.99)*255+0.5);
  h = mrvWaitbar(0,'Performing eddy current correction...');
  for(d=2:nDirs)
    xf{d} = mrAnatRegister(imVol(:,:,:,d), b0);
    tmpIm = mrAnatResliceSpm(imVol(:,:,:,d),xf{d},[],[1 1 1],[7 7 7 0 0 0],0);
    tmpIm(isnan(tmpIm)) = 0;
    tmpIm(tmpIm<0) = 0;
    imVol(:,:,:,d) = tmpIm;
    mrvWaitbar(d/nDirs,h);
  end
  close(h);
end
imVol = int16(round(imVol));
return;

% Showing a movie (to see the image mis-alignment)
for(d=1:nDirs)
  f = squeeze(imVol(:,:,20,d));
  f = uint8(f./max(f(:)).*255+0.5);
  m(d) = im2frame(f,gray(256)); 
end
figure(99); 
image(f); colormap(gray(256));
truesize; axis off
movie(m,1,5);
