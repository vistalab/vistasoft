function [b0, fa, add, ci, meanDiff, maxEig, medEig, minEig, maxVec, mmPerPix] = dtiLoadTensorcalc(basename)
% [b0, fa, add, ci, meanDiff, maxEig, medEig, minEig, maxVec, mmPerPix] = dtiLoadTensorcalc([basename])
%
% If basename is empty or not passed, a file browser is invoked. 
%
% Loads data from the from the tensorcalc-format 'Tensor.float' file.
% Tensor.float files are 32-bit floating point arrays (raw data- no header) 
% containing the following maps:
% 
% 1. Mean diffusivity (or Trace/3, units x106 mm2/s)
% 2. Maximum eigenvalue
% 3. Medium eigenvalue 
% 4. Minimum eigenvalue 
% 5. X component of the maximum eigenvector (values between -1 and 1) 
% 6. Y component of the maximum eigenvector 
% 7. Z component of the maximum eigenvector 
% 8. Fractional Anisotropy, FA (multiplied by 1000) 
% 9. Lattice index, Add (if asked for via -Add option) 
% 10. Coherence index, CI (if asked for via -CI option) 
% 11. b=0 image (arbitrary units) 
%
% HISTORY:
% 2002.08.16 RFD (bobd@stanford.edu) Wrote it.
%
% TODO:
%

if(~exist('basename', 'var') | isempty(basename))
    [f,p] = uigetfile({'Tensor.float.001*';'*.*'}, 'Select a Tensor.float file...');
    if(isnumeric(f))
        exit;
    end
    %[junk,f] = fileparts(f);
    basename = fullfile(p,f);
end
% Remove all extensions from filename
[p,f,e] = fileparts(basename);
if(strcmpi(e,'.gz'))
    gz = 1;
    [p,f,e] = fileparts(fullfile(p,f));
else
    gz = 0;
end
basename = fullfile(p, f);
% Now, look for a B0 file to get some info. We are forced to do this ugly
% hack because the tensor.float file has no header.
d = getIfileNames(fullfile(fileparts(basename),'B0'));
nslices = length(d);
if(nslices>=1)
    b0File = d{1};
else
    warning('B0 file not found- pixel size and image dimensions cannot be determined. Guessing...');
    imdim = [128,128,length(dir([basename,'.*']))];
    mmPerPix = [2.0313,2.0313,3.0];
end
        
if(exist(b0File,'file'))
    [su,ex,se,im] = readIfileHeader(b0File);
    imdim = [im.dim_X, im.dim_Y, nslices];
    mmPerPix = [im.pixsize_X, im.pixsize_Y, im.slthick];
elseif(exist([b0File '.gz'],'file') | exist([b0File '.GZ'],'file'))
    gunzip(b0File);
    [su,ex,se,im] = readIfileHeader(b0File);
    imdim = [im.dim_X, im.dim_Y, nslices];
    mmPerPix = [im.pixsize_X, im.pixsize_Y, im.slthick];
    gzip(bofile);
end

meanDiff = zeros(imdim);
maxEig = zeros(imdim);
medEig = zeros(imdim);
minEig = zeros(imdim);
maxVec = zeros([imdim,3]);
fa = zeros(imdim);
add = zeros(imdim);
ci = zeros(imdim);
b0 = zeros(imdim);
for(ii=1:imdim(3))
    fname = sprintf('%s.%03d', basename, ii);
    if(gz)
        gunzip(fname);
        fid = fopen(fname, 'rb', 'ieee-be');
        tmp = fread(fid, inf, 'float32');
        fclose(fid);
        gzip(fname);
    else
        % 2004.03.26 RFD: Data now in ieee-le format?
        fid = fopen(fname, 'rb', 'ieee-be');
        tmp = fread(fid, inf, 'float32');
        fclose(fid);
    end
    numImages = size(tmp,1)./prod(imdim(1:2));
    tmp = reshape(tmp,[imdim(1),imdim(2),numImages]);
    meanDiff(:,:,ii) = tmp(:,:,1);
    maxEig(:,:,ii) = tmp(:,:,2);
    medEig(:,:,ii) = tmp(:,:,3);
    minEig(:,:,ii) = tmp(:,:,4);
    maxVec(:,:,ii,1) = tmp(:,:,5);
    maxVec(:,:,ii,2) = tmp(:,:,6);
    maxVec(:,:,ii,3) = tmp(:,:,7);
    fa(:,:,ii) = tmp(:,:,8);
    add(:,:,ii) = tmp(:,:,9);
    if(numImages==13)
        ci(:,:,ii) = tmp(:,:,11);
    else
        ci = tmp(:,:,10);
    end
    b0(:,:,ii) = tmp(:,:,numImages);
    % sometimes there is an extra image?
end
%numImages

return;

% General notes about tensorcalc data:
% Each slice is in a separate file. Included are two different data file types,
% Tensor.float and Vectors.float. Tensor.float contains most of the info that
% you would need to do fiber tracing, except that it does not contain the 
% eigenvectors corresponding to the two smaller eigenvalues. Vectors.float 
% contains all 3 eigenvectors. (For more info about these files, see 
% http://sirl.stanford.edu/dwi/maj/)
% 



