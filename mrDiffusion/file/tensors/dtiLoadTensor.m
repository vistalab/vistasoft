function [eigVec, eigVal, mmPerVox] = dtiLoadTensor(vectorsBasename, tensorBasename, b0Basename)
% [eigVec, eigVal, mmPerVox] = dtiLoadTensor([vectorsBasename], [tensorBasename], [b0Basename])
% 
% 'eigVec' is a 5d array- a 3d array of 3x3 eigenVectors. 
% To get the eigenVector for a particular voxel, use: v = eigVec(x,y,z,:,:);
%
% If you also provide the 'Tensor.float' file, then the eigen values are
% also returned (eigVal).
%
% If you provide the B0 filename, then we can get some useful info from the
% header, like the voxel dimensions.
%
% Loads the 3x3 matrix from the tensorcalc-format 'Vectors.float' file.
% The Vectors.float files are 32-bit floating point arrays (raw data- no header) 
% with 9 images per file: 
%   X1, Y1, Z1 = (signed) components of the eigenvector corresponding to the 
%                largest eigenvalue. 
%   X2, Y2, Z2 = (signed) components of the eigenvector corresponding to the 
%                middle eigenvalue. 
%   X3, Y3, Z3 = (signed) components of the eigenvector corresponding to the 
%                smallest eigenvalue.  
% All vectors are unit vectors.
%
%
% HISTORY:
% 2002.08.16 RFD (bobd@stanford.edu) Wrote it.
% 2003.11.13 RFD changed to return eigen vectors and values separately.
% 2003.11.26 RFD- we now get some useful info from the B0 header, if it's available.
%
% TODO:
%
%
% EXAMPLE:
% [eigVec,eigVal] = dtiLoadTensor('Vectors.float','Tensor.float');
% meanDiffusivity = sum(eigVal,4)/3;
% stdevDiffusivity = sqrt(sum((eigVal-repmat(meanDiffusivity,[1,1,1,3])).^2,4));
% normDiffusivity = sqrt(sum(eigVal.^2,4));
% fa = sqrt(3/2).*(stdevDiffusivity./normDiffusivity);
% 

if(~exist('vectorsBasename', 'var') | isempty(vectorsBasename))
    [f,p] = uigetfile({'*.001';'*.*'},'Select a slice from the Vectors file...');
    vectorsBasename = fullfile(p,f(1:end-3));
    tensorBasename = fullfile(p,'Tensor.float.');
    b0Basename = fullfile(p,'B0.');
end
if(~exist('tensorBasename', 'var') | isempty(tensorBasename))
    tensorBasename = fullfile(fileparts(vectorsBasename),'Tensor.float.');
else
    if(tensorBasename(end) ~= '.')
        tensorBasename = [tensorBasename '.'];
    end
end
if(~exist('b0Basename', 'var') | isempty(b0Basename))
    b0Basename = fullfile(fileparts(vectorsBasename),'B0.');
else
    if(b0Basename(end) ~= '.')
        b0Basename = [b0Basename '.'];
    end
end

if(vectorsBasename(end) ~= '.')
    vectorsBasename = [vectorsBasename '.'];
end

nSlices = length(dir([vectorsBasename,'*']));
if(~isempty(b0Basename))
    [su,ex,se,im] = readIfileHeader([b0Basename,'001']);
    imdim = [im.imatrix_X, im.imatrix_Y, nSlices];
    mmPerVox = [im.pixsize_X, im.pixsize_Y, im.slthick];
else
    warning('B0 file not provided- guessing parameters!');
    mmPerVox = [260/128 260/128 3];
    % Now try to guess the image size
    d = dir([vectorsBasename,'001']);
    % OK- there are 9*4=36 bytes per voxel -> d.bytes/36 voxels. log2 tells us
    % how many bits this requires. We assume that the bits are divided equally
    % between X and Y (thus the /2), and then convert from bits to decimal (2^)
    xySize = 2^(log2(d.bytes./36)./2);
    imdim = [xySize,xySize,nSlices];
    disp(['I''m guessing that the image dimension is [',num2str(imdim),'].']);
end

npix = imdim(1)*imdim(2);
eigVec = zeros([imdim,3,3]);
if(~isempty(tensorBasename))
    eigVal = zeros([imdim,3]);
else
    eigVal = [];
end
disp(['Reading ',num2str(nSlices),' slices...']);
for(ii=1:imdim(3))
    fname = sprintf('%s%03d', vectorsBasename, ii);
    fid = fopen(fname, 'rb', 'ieee-be');
    eigVec(:,:,ii,:,:) = reshape(fread(fid, inf, 'float32'),[imdim(1),imdim(2),1,3,3]);
    fclose(fid);
    % Unfortunately, tensorcalc stores only the unit vectors in the Vectors
    % file. So, we need to open up the corresponding Tensor file and get
    % the eigenvalues from there.
    if(~isempty(tensorBasename))
        fname = sprintf('%s%03d', tensorBasename, ii);
        % 2004.03.26 RFD: Data now in ieee-le format?
        fid = fopen(fname, 'rb', 'ieee-be');
        % The eigen values are in the 2:4 sections of the Tensor.float
        % file.  Here, we just read the first four sections.
        tmp = fread(fid, npix*4, 'float32');
        % Drop the first section, since it's the mean diffusivity.
        tmp = tmp(npix+1:end);
        fclose(fid);
        eigVal(:,:,ii,1) = reshape(tmp(1:npix), imdim(1), imdim(2));
        eigVal(:,:,ii,2) = reshape(tmp(npix+1:npix*2), imdim(1), imdim(2));
        eigVal(:,:,ii,3) = reshape(tmp(npix*2+1:npix*3), imdim(1), imdim(2));
    end
end
return;

% Genreal notes about tensorcalc data:
% Each slice is in a separate file. Included are two different data file types,
% Tensor.float and Vectors.float. Tensor.float contains most of the info that
% you would need to do fiber tracing, except that it does not contain the 
% eigenvectors corresponding to the two smaller eigenvalues. Vectors.float 
% contains all 3 eigenvectors. (For more info about these files, see 
% http://sirl.stanford.edu/dwi/maj/)
% 
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
% Sample matlab code to read these files:
% 
% baseName = 'Tensor.float.';
% imDim = [128,128,38];
% meanDiffusion = zeros(imDim);
% maxEigVal = zeros(imDim);
% medEigVal = zeros(imDim);
% minEigVal = zeros(imDim);
% maxEigValX = zeros(imDim);
% maxEigValY = zeros(imDim);
% maxEigValZ = zeros(imDim);
% fa = zeros(imDim);
% for(ii=1:imDim(3))
%     fname = sprintf('%s%03d', baseName, ii);
%     fid = fopen(fname, 'rb', 'ieee-be');
%     tmp = reshape(fread(fid, inf, 'float32'),[imDim(1),imDim(2),11]);
%     fclose(fid);
%     meanDiffusion(:,:,ii) = tmp(:,:,1);
%     maxEigVal(:,:,ii) = tmp(:,:,2);
%     medEigVal(:,:,ii) = tmp(:,:,3);
%     minEigVal(:,:,ii) = tmp(:,:,4);
%     maxEigValX(:,:,ii) = tmp(:,:,5);
%     maxEigValY(:,:,ii) = tmp(:,:,6);
%     maxEigValZ(:,:,ii) = tmp(:,:,7);
%     fa(:,:,ii) = tmp(:,:,8);
%     b0(:,:,ii) = tmp(:,:,11);
% end




