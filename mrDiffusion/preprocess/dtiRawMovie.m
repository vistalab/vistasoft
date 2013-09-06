function dtiRawMovie(dwRaw, ecXform, sliceNum, outBaseName)
%
% dtiRawMovie(dwRaw, ecXform, sliceNum, outBaseName)
%
% Make a movie from a specified slice in the 4-d set of volumes (dwRaw),
% first applying the eddy/motion correction params in ecXform. If an output
% name is given, the movie will be saved as an animated gif.
% 
% HISTORY:
% 2007.02.?? RFD wrote it.
%

if(~exist('dwRaw','var')||isempty(dwRaw))
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

if(~exist('ecXform','var')||isempty(ecXform))
  fn = [fullfile(dataDir,inBaseName) 'EddyCorrectXforms.mat'];
  [f,p] = uigetfile({'*.mat'},'Select an eddy-correct transform file...',fn);
  if(isnumeric(f)), disp('User canceled.'); return; end
  ecXform = fullfile(p,f); 
end

if(~exist('outBaseName','var')) outBaseName = []; end

% If file names were specified, load the data
if(ischar(ecXform))
    load(ecXform);
else
    xform = ecXform;
end
if(ischar(dwRaw))
    disp(['Loading raw data ' dwRaw '...']);
    dwRaw = niftiRead(dwRaw);
end

sz = size(dwRaw.data);

if(~exist('sliceNum','var')||isempty(sliceNum))
    sliceNum = round(sz(3)/2);
end
[X,Y,Z] = ndgrid([1:sz(1)],[1:sz(2)],[sliceNum]);
x = [X(:)'; Y(:)'; Z(:)']; clear X Y Z;

M = zeros(sz([1,2,4]),'uint8');
Mwarp = M;
% TODO: extract the slice first, then do histogram clipping. Need to use
% myCinterp3, though.
dwRaw.data = single(dwRaw.data);
for(ii=1:sz(4))
    if(mod(ii,30)==0), fprintf('Processing vol %d of %d...\n',ii,sz(4)); end
    sl = reshape(mrAnatFastInterp3(dwRaw.data(:,:,:,ii), x), sz(1:2));
    M(:,:,ii) = uint8(round(mrAnatHistogramClip(sl,0.4,0.99)*255));
    sl = reshape(mrAnatFastInterp3(dwRaw.data(:,:,:,ii), x, [xform(ii).ecParams xform(ii).phaseDir]), sz(1:2));
    Mwarp(:,:,ii) = uint8(round(mrAnatHistogramClip(sl,0.4,0.99)*255));
end
M = flipdim(permute(M,[2,1,3]),1);
Mwarp = flipdim(permute(Mwarp,[2,1,3]),1);

sz = size(M);

% Autocrop the movie frames
mask = imblur(mean(M,3),2)>40&imblur(mean(Mwarp,3),2)>40;
tmp = find(sum(mask,2));
crop(:,1) = [min(tmp) max(tmp)];
tmp = find(sum(mask,1));
crop(:,2) = [min(tmp) max(tmp)];
pad = 5;
if(any(diff(crop)./sz([1:2]) < 0.8))
    crop(1,:) = max([1 1],crop(1,:)-pad);
    crop(2,:) = min(sz([1:2]),crop(2,:)+pad);
    [X,Y,Z] = ndgrid([crop(1,1):crop(2,1)],[crop(1,2):crop(2,2)],[1:sz(3)]);
    x = sub2ind(sz,X(:), Y(:), Z(:)); clear X Y Z;
    newSz = [diff(crop)+1 sz(3)];
    M = reshape(M(x),newSz);
    Mwarp = reshape(Mwarp(x),newSz);
end

if(isempty(outBaseName))
    mpOrig = mplay(int2struct(M),10);
    mpWarp = mplay(int2struct(Mwarp),10);
else
    % Save a gif. Cropping and using only 64 colors makes for a
    % fairly compact file, suitable for a website. Using 256 colors
    % might make a slightly nicer image.
    M = M./4; M(M>63) = 63;
    Mwarp = Mwarp./4; Mwarp(Mwarp>63) = 63;
    % The gif writer wants a 4d dataset (???)
    M = reshape(M,[size(M,1),size(M,2),1,size(M,3)]);
    imwrite(M,gray(64),[outBaseName '_orig.gif'],'DelayTime',0.1,'LoopCount',65535);
    Mwarp = reshape(Mwarp,[size(Mwarp,1),size(Mwarp,2),1,size(Mwarp,3)]);
    imwrite(Mwarp,gray(64),[outBaseName '_warp.gif'],'DelayTime',0.1,'LoopCount',65535);
end

return;
