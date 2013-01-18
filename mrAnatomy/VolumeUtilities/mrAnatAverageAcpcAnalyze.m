function mrAnatAverageAcpcAnalyze(fileNameList, outFileBaseName, alignLandmarks, newMmPerVox, weights, bb, clipVals, showFigs);
%
% mrAnatAverageAcpcAnalyze(fileNameList, outFileBaseName, [alignLandmarks=[]], ...
%                          [newMmPerVox=[1 1 1]], [weights=ones(size(fileNameList))], ...
%                          [bb], [clipVals], [showFigs=1])
%
% Reslices the first analyze file to ac-pc space at
% 1x1x1mm resolution and then aligns all the rest of the analyze
% files to that one and averages them all together.
%
% You can specify the ac-pc landmarks as a 3x3 matrix of the form:
%  [ acX, acY, acZ; pcX, pcY, pcZ; midSagX, midSagY, midSagZ ]
% Where:
%  X is the (left -> right) location of a point,
%  Y is the (posterior -> anterior) location of a point, 
%  Z is the (inferior -> superior) location of a point,
% ac is the anterior commissure, pc is the posterior commissure, and midSag
% is another poit in the mid-sagittal plane that is somewhat distant from
% the ac-pc line. These 3 points define the rotation/translation into ac-pc
% space. If the ac is properly set in the image header, then you can just
% pass in the pc and midSag coords, specified as the offset from the ac.
%
% If these landmarks aren't provided, then the xform from the image header
% is used. Note that if the image origin isn't close to the AC, then the
% default bounding box ([-90,90; -126,90; -72,108]') won't be appropriate. 
%
% weights specifies the weighting factor to be applied to each of the input
% images (fileNameList). 
%
% REQUIRES:
%  * Stanford anatomy tools (eg. /usr/local/matlab/toolbox/mri/Anatomy)
%  * spm2 tools (eg. /usr/local/matlab/toolbox/mri/spm2)
%
% HISTORY:
% 2004.11.10 RFD (bob@white.stanford.edu) wrote it, based on averageAnalyze
if ~exist('showFigs','var') | isempty(showFigs), showFigs = 1; end

if (~exist('fileNameList','var') | isempty(fileNameList) | ...
        ~exist('outFileBaseName','var') | isempty(outFileBaseName))
    help(mfilename);
    return;
end
if (~exist('newMmPerVox','var') | isempty(newMmPerVox))
    newMmPerVox = [1 1 1];
end
if ~exist('saveIntermediate','var') | isempty(saveIntermediate)
  saveIntermediate = 0; 
end

if (~exist('alignLandmarks','var')) alignLandmarks = []; end

if ~exist('weights','var') | isempty(weights)
  weights = ones(size(fileNameList)); 
end

if(~exist('bb','var') | isempty(bb))
    % Bounding box, in physical space (ie. mm from the origin, which should be
    % at or near the AC).
    bb = [-90,90; -126,90; -72,108]';
end

if (~exist('clipVals','var')) clipVals = []; end

% from spm_bsplins:  
% d(1:3) - degree of B-spline (from 0 to 7) along different dimensions
% d(4:6) - 1/0 to indicate wrapping along the dimensions
% not sure what wrapping is, but '7' is the highest quality (but slowest).
bSplineParams = [7 7 7 0 0 0];

% We explicitly initialize the spm_defaults global here, and ensure that
% the analyze_flip option is turned off. (Our analyze files are never
% right-left reversed!)
spm_defaults;
defaults.analyze.flip = 0;

numImages = length(fileNameList);

% Load the first image (the reference)
[refImg,mmPerVox,refImgHdr] = loadAnalyze(fileNameList{1});

if(isempty(clipVals))
  clipVals = repmat([0.4 0.98],numImages,1);
end
  
refImg = mrAnatHistogramClip(refImg, clipVals(1,1), clipVals(1,2));
%[refImg, lc, uc] = mrAnatHistogramClipOptimal(refImg, 99);
%fprintf('\nClipped reference image at [%0.1f, %0.1f].\n', lc, uc);

if(isempty(alignLandmarks))
    % *** TO DO: allow user to select the landmarks!
    tal2ref = inv(refImgHdr.mat);
    
else
    if(size(alignLandmarks,1)==2)
        origin = inv(refImgHdr.mat)*[0 0 0 1]'-0.5;
        %origin(3) = size(refImg,3)-origin(3);
        %alignLandmarks(:,3) = -alignLandmarks(:,3);
        origin = origin(1:3)';
        imY = alignLandmarks(1,:); imY = imY./norm(imY);
        imZ = alignLandmarks(2,:); imZ = imZ./norm(imZ);
    else
        %% flip 3rd axis
        %alignLandmarks(:,3) = size(refImg,3)-alignLandmarks(:,3);
        % The first landmark should be the anterior commissure (AC)- our origin
        origin = alignLandmarks(1,:);
        % Define the current image axes by re-centering on the origin (the AC)
        imY = alignLandmarks(2,:)-origin; imY = imY./norm(imY);
        imZ = alignLandmarks(3,:)-origin; imZ = imZ./norm(imZ);
    end
    % x-axis (left-right) is the normal to [ac, pc, mid-sag] plane
    imX = cross(imZ,imY);
    % Make sure the vectors point right, superior, anterior
    if(imX(1)<0) imX = -imX; end
    if(imY(2)<0) imY = -imY; end
    if(imZ(3)<0) imZ = -imZ; end
    % Project the current image axes to the cannonical AC-PC axes. These
    % are defined as X=[1,0,0], Y=[0,1,0], Z=[0,0,1], with the origin
    % (0,0,0) at the AC. Note that the following are the projections
    x = [0 1 imY(3)]; x = x./norm(x);
    y = [1  0 imX(3)]; y = y./norm(y);
    %z = [0  imX(2) 1]; z = z./norm(z);
    z = [0  -imY(1) 1]; z = z./norm(z);
    % Define the 3 rotations using the projections. We have to set the sign
    % of the rotation, depending on which side of the plane we came from.
    rot(1) = sign(x(3))*acos(dot(x,[0 1 0])); % rot about x-axis (pitch)
    rot(2) = sign(y(3))*acos(dot(y,[1 0 0])); % rot about y-axis (roll)
    rot(3) = sign(z(2))*acos(dot(z,[0 0 1])); % rot about z-axis (yaw)
    
    scale = mmPerVox;
    
    % Affine build assume that we need to translate before rotating. But,
    % our rotations have been computed about the origin, so we'll pass a
    % zero translation and set it ourselves (below).
    ref2tal = affineBuild([0 0 0], rot, scale, [0 0 0]);
    tal2ref = inv(ref2tal);
    
    % Insert the translation.
    tal2ref(1:3,4) = [origin+newMmPerVox/2]';
end

% Resample it to 1x1x1
disp('Resampling reference image to ac-pc space, isotropic voxels...');
[newRefImg,xform] = mrAnatResliceSpm(refImg, tal2ref, bb, newMmPerVox, bSplineParams, showFigs);
newOrigin = inv(xform)*[0 0 0 1]'; newOrigin = newOrigin(1:3)'-newMmPerVox/2;
% Reclip in case the interpolation introduced out-of-range values
newRefImg(newRefImg<0) = 0; newRefImg(newRefImg>1) = 1;
if(showFigs)
    o = round(newOrigin);
    figure; set(gcf,'Name',[fileNameList{1} ' (ref)']);
    subplot(1,3,1); imagesc(flipud(squeeze(newRefImg(:,:,o(3)))')); axis image; colormap gray;
    subplot(1,3,2); imagesc(flipud(squeeze(newRefImg(:,o(2),:))')); axis image; colormap gray;
    subplot(1,3,3); imagesc(flipud(squeeze(newRefImg(o(1),:,:))')); axis image; colormap gray;
    %imagesc(makeMontage(refImg,[20:4:size(newRefImg,3)-18]));axis image;colormap gray;
    %title([fileNameList{1} ' (reference image) aligned.']);
    pause(0.1);
end
Vref.uint8 = uint8(round(newRefImg.*255));
Vref.mat = xform;

outImg = newRefImg.*weights(1);
numSamples = zeros(size(outImg));
nans = isnan(outImg);
numSamples(~nans) = weights(1);
outImg(nans) = 0;
for(ii=2:numImages)
    if(saveIntermediate)
        % We do this first since the final result will be saved after this loop.
        fname = sprintf('%s_%d',outFileBaseName,ii-1);
        disp(['writing intermediate result ',fname,'...']);
        img = outImg;
        nz = numSamples>0;
        img(nz) = img(nz)./numSamples(nz);
        img = img-min(img(:));
        img = int16(img.*(32767/max(img(:))));
        saveAnalyze(img, fname, newMmPerVox, ['AVERAGE:' refImgHdr.descrip], newOrigin);
    end
    fprintf('Aligning %s to reference image...\n',fileNameList{ii});
    [img,mmPerVox,hdr] = loadAnalyze(fileNameList{ii});
    img = mrAnatHistogramClip(img, clipVals(ii,1), clipVals(ii,2));
    %[img, lc, uc] = mrAnatHistogramClipOptimal(img, 99);
    %fprintf('Clipped image %d at [%0.1f, %0.1f].\n', ii, lc, uc);
    Vin.uint8 = uint8(round(img.*255));
    Vin.mat = hdr.mat;
    %transRot = spm_coreg(Vin, Vref);
    %xform = spm_matrix(transRot(:)')*Vin.mat\Vref.mat*inv(Vref.mat);
    transRot = spm_coreg(Vref, Vin);
    xform = inv(Vin.mat)*spm_matrix(transRot(:)');    
    fprintf('Resampling %s to reference image...\n',fileNameList{ii});
    [img,xform] = mrAnatResliceSpm(img, xform, bb, newMmPerVox, bSplineParams, showFigs);
    % Reclip in case the interpolation introduced out-of-range values
    img(img<0) = 0; img(img>1) = 1;
    if(showFigs)
        o = round(newOrigin);
    	figure; set(gcf,'Name',[fileNameList{ii}]);
        subplot(1,3,1); imagesc(flipud(squeeze(img(:,:,o(3)))')); axis image; colormap gray;
        subplot(1,3,2); imagesc(flipud(squeeze(img(:,o(2),:))')); axis image; colormap gray;
        subplot(1,3,3); imagesc(flipud(squeeze(img(o(1),:,:))')); axis image; colormap gray;
        %figure; imagesc(makeMontage(img,[20:4:size(img,3)-18])); axis image; colormap gray;
        %title([fileNameList{ii} ' aligned.']);
        pause(0.1);
    end
    nans = isnan(img);
    numSamples(~nans) = numSamples(~nans)+weights(ii);
    img(nans) = 0;
    outImg = outImg+img.*weights(ii);
end
% Rescale based on the number of samples at each voxel
nz = numSamples>0;
outImg(nz) = outImg(nz)./numSamples(nz);

if(showFigs)
    o = round(newOrigin);
    figure; set(gcf,'Name',['Average']);
    subplot(1,3,1); imagesc(flipud(squeeze(outImg(:,:,o(3)))')); axis image; colormap gray;
    subplot(1,3,2); imagesc(flipud(squeeze(outImg(:,o(2),:))')); axis image; colormap gray;
    subplot(1,3,3); imagesc(flipud(squeeze(outImg(o(1),:,:))')); axis image; colormap gray;
    figure; imagesc(makeMontage(outImg,[20:4:size(outImg,3)-18])); axis image; colormap gray;
    title(['Average aligned.']);
    pause(0.1);
end

% rescale to 15 bits (0-32767)
outImg = outImg-min(outImg(:));
outImg = int16(outImg.*(32767/max(outImg(:))));

disp(['writing ',outFileBaseName,'...']);
hdr = saveAnalyze(outImg, outFileBaseName, newMmPerVox, ['AVERAGE:' refImgHdr.descrip], newOrigin);

return;
