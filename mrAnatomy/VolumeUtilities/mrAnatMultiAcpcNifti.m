function [outImg] = mrAnatMultiAcpcNifti(fileNameList, outFileName,...
    storedAnatomy, newMmPerVox, weights, bb, showFigs, clipVals)
% [outImg] = mrAnatMultiAcpcNifti(fileNameList, outFileName, ...
% storedAnatomy, newMmPerVox, weights, bb, showFigs, clipVals)
%
% adapted from mrAnatAverageAcpcNifti.m
%
% The purpose is to align one t1-anatomical image (the first image in the
% cell fileNameList) to  a stored t1 (storedAnatomy). Additional file paths
% in fileNameList will be subjected to the same transformation as that used
% for the first file.
%
%  The bulk of the function is the same as mrAnatAverageAcpcNifti. It would
%  thus be convenient (and easier to read) if the bulk of the code were
%  made into separate routines.


%------------------------------------------------------------------------
% Variable check 
if (~exist('newMmPerVox','var') || isempty(newMmPerVox))
    newMmPerVox = [1 1 1];
    mmSentIn = false;
else
    mmSentIn = true;
end

if(~exist('showFigs','var') || isempty(showFigs)), showFigs = true; end

if(~exist('storedAnatomy','var')), storedAnatomy = []; end

if(~exist('weights','var') || isempty(weights)), weights = ones(size(fileNameList)); end

if(~exist('bb','var') || isempty(bb))
    % Bounding box, in physical space (ie. mm from the origin, which should be
    % at or near the AC).
    bb = [-90,90; -126,90; -72,108]';
end

if (~exist('clipVals','var')), clipVals = []; end
%------------------------------------------------------------------------

for ii=1:length(fileNameList)
    if ~exist(fileNameList{ii},'file')
        error([fileNameList{ii} ' does not exist!']); 
    end
end

% from spm_bsplins:
% d(1:3) - degree of B-spline (from 0 to 7) along different dimensions
% d(4:6) - 1/0 to indicate wrapping along the dimensions
% not sure what wrapping is, but '7' is the highest quality (but slowest).
bSplineParams = [7 7 7 0 0 0];

% We explicitly initialize the spm_defaults global here, and ensure that
% the analyze_flip option is turned off. (Our analyze files are never
% right-left reversed!)
spm_defaults;
defaults.analyze.flip = 0; %#ok<*STRNU>

numImages = length(fileNameList);
for ii=1:numImages
    if(length(fileNameList{ii})<7||~strcmpi(fileNameList{ii}(end-6:end),'.nii.gz'))
        fileNameList{ii} = [fileNameList{ii} '.nii.gz'];
    end
end

% Load the first image (the image to align)
ni = niftiRead(fileNameList{1});
ni = niftiApplyCannonicalXform(ni);
refDescrip = ni.descrip;

if(isempty(clipVals))
    clipVals = repmat([0.4 0.98],numImages,1);
end

refImg = mrAnatHistogramClip(double(ni.data(:,:,:,1)), clipVals(1,1), clipVals(1,2));

if(ischar(storedAnatomy))
    % Assume that storedAnatomy is an image to align with. For now,
    % we assume that it is a dt6 file or a nifti file.
    % TODO: allow an analyze or nifti image file to be passed.
    [p,f,e] = fileparts(storedAnatomy); %#ok<*ASGLU>
    disp(['Aligning reference image to the template image in ' f '...']);
    if(strcmpi(e,'.nii')||strcmpi(e,'.gz'))
        tmp = niftiRead(storedAnatomy);
        img = tmp.data;
        acpcXform = tmp.qto_xyz;
        mmPerVox = tmp.pixdim(1:3);
        clear tmp;
    elseif(strcmpi(e,'.img')||strcmpi(e,'.hdr'))
        [img,mmPerVox,tmp] = loadAnalyze(storedAnatomy);
        acpcXform = tmp.mat;
        clear tmp;
    elseif(strcmpi(e,'.mat'))
        tmp = load(storedAnatomy,'anat');
        img = tmp.anat.img;
        acpcXform = tmp.anat.xformToAcPc;
        mmPerVox = tmp.anat.mmPerVox;
        clear tmp;
    else
        error('Unrecognized template format.');
    end
    if(~all(newMmPerVox==mmPerVox)&&~mmSentIn)
        newMmPerVox = mmPerVox;
        warning('Overriding specificed mmPerVox to match that of the specified template image (%0.1f %0.1f %0.1f).\n',newMmPerVox(1),newMmPerVox(2),newMmPerVox(3)); %#ok<*WNTAG>
    end
    img(isnan(img)) = 0;
    Vref.uint8 = uint8(round(mrAnatHistogramClip(double(img), clipVals(1,1), clipVals(1,2)).*255+.5));
    Vref.mat = acpcXform;
    refImg(isnan(refImg)) = 0;
    Vin.uint8 = uint8(round(refImg.*255+0.5));
    Vin.mat = ni.qto_xyz;
    transRot = spm_coreg(Vref, Vin);
    xform = Vin.mat\spm_matrix(transRot(end,:));
    fprintf('Resampling reference to template image space...\n');
    [refImg,refXform] = mrAnatResliceSpm(refImg, xform, bb, newMmPerVox, bSplineParams, showFigs);
    storedAnatomy = [];
elseif(numel(storedAnatomy)==1)
    % -1, 0, false, etc. means that we use the qform matrix from the first image.
    fprintf('Resampling reference image to acpc space...\n');
    [refImg,refXform] = mrAnatResliceSpm(refImg, ni.qto_ijk, bb, newMmPerVox, bSplineParams, showFigs);
    storedAnatomy = [];
end


if(~isempty(storedAnatomy))
    if(size(storedAnatomy,1)==2)
        origin = ni.qto_ijk*[0 0 0 1]'-0.5;
        origin = origin(1:3)';
        imY = storedAnatomy(1,:); imY = imY./norm(imY);
        imZ = storedAnatomy(2,:); imZ = imZ./norm(imZ);
    else
        %% flip 3rd axis
        %storedAnatomy(:,3) = size(refImg,3)-storedAnatomy(:,3);
        % The first landmark should be the anterior commissure (AC)- our origin
        origin = storedAnatomy(1,:);
        % Define the current image axes by re-centering on the origin (the AC)
        imY = storedAnatomy(2,:)-origin; imY = imY./norm(imY);
        imZ = storedAnatomy(3,:)-origin; imZ = imZ./norm(imZ);
    end

    % x-axis (left-right) is the normal to [ac, pc, mid-sag] plane
    imX = cross(imZ,imY);
    % Make sure the vectors point right, superior, anterior
    if(imX(1)<0), imX = -imX; end
    if(imY(2)<0), imY = -imY; end
    
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

    scale = ni.pixdim;
    % Affine build assumes that we need to translate before rotating. But,
    % our rotations have been computed about the origin, so we'll pass a
    % zero translation and set it ourselves (below).
    ref2tal = affineBuild([0 0 0], rot, scale, [0 0 0]);
    tal2ref = inv(ref2tal);
    % Insert the translation.
    tal2ref(1:3,4) = (origin+newMmPerVox/2)';

    % Resample it to 1x1x1
    disp('Resampling reference image to ac-pc space, isotropic voxels...');
    [refImg,refXform] = mrAnatResliceSpm(refImg, tal2ref, bb, newMmPerVox, bSplineParams, showFigs);
end

newOrigin = refXform\[0 0 0 1]'; newOrigin = newOrigin(1:3)'-newMmPerVox/2;
% Reclip in case the interpolation introduced out-of-range values
refImg(refImg<0|isnan(refImg)) = 0; refImg(refImg>1) = 1;
if(showFigs)
    o = round(newOrigin);
    figure; set(gcf,'Name',[fileNameList{1} ' (ref)']);
    subplot(1,3,1); imagesc(flipud(squeeze(refImg(:,:,o(3)))')); axis image; colormap gray;
    subplot(1,3,2); imagesc(flipud(squeeze(refImg(:,o(2),:))')); axis image; colormap gray;
    subplot(1,3,3); imagesc(flipud(squeeze(refImg(o(1),:,:))')); axis image; colormap gray;
    %imagesc(makeMontage(refImg,[20:4:size(refImg,3)-18]));axis image;colormap gray;
    %title([fileNameList{1} ' (reference image) aligned.']);
    pause(0.1);
end
Vref.uint8 = uint8(round(refImg.*255));
Vref.mat = refXform;

outImg = refImg.*weights(1);
numSamples = zeros(size(outImg));
nans = isnan(outImg);
numSamples(~nans) = weights(1);
outImg(nans) = 0;
outNifti = cell(1, numImages);

for ii=1:numImages
    if(ii==1)
        startInd = 2;
        outNifti{1} = outImg;        
        isclassfile(ii) = 0;

    else
        startInd = 1;
        % ni = niftiRead(fileNameList{ii});
        % ni = niftiApplyCannonicalXform(ni);                
        ni = niftiRead(fileNameList{ii});                  
        refDescrip = ni.descrip;
    end

    if(isempty(ni.data)), error('NIFTI file error (%s)!',fileNameList{ii}); end
    %endInd = size(ni.data,4);
    endInd = min(2,size(ni.data,4));
    for jj=startInd:endInd
        fprintf('Aligning image %d of %s to reference image...\n',jj,fileNameList{ii});
        
        % if our nifti is a class file, we treat resample in a way that
        % preserves integer values and integrity of each layer. if not, we
        % resample with splines, as we did for our first image...        
        if isequal(round(ni.data), ni.data) && length(unique(ni.data)) < 255 
            isclassfile(ii) = 1;
            disp('resampling class files...');            
            clsBins = unique(ni.data(ni.data(:)>0));
            img = zeros(size(outImg),'uint8');
            for thisclass=1:length(clsBins)
                tmp = mrAnatResliceSpm(double(ni.data==clsBins(thisclass)),xform,bb,newMmPerVox,[0 0 0 1 1 1],showFigs);
                img(tmp>=0.5) = clsBins(thisclass);
            end
            
        else
            isclassfile(ii) = 0;
            img = mrAnatHistogramClip(double(ni.data(:,:,:,jj)), clipVals(ii,1), clipVals(ii,2));
            img(isnan(img)) = 0;
            Vin.uint8 = uint8(round(img.*255));
            Vin.mat = ni.qto_xyz;
            %transRot = spm_coreg(Vref, Vin);
            %xform = inv(Vin.mat)*spm_matrix(transRot(end,:));
            fprintf('Resampling %s to reference image...\n',fileNameList{ii});
            
            [img,xform] = mrAnatResliceSpm(img, xform, bb, newMmPerVox, bSplineParams, showFigs);
            % Reclip in case the interpolation introduced out-of-range values
            img(img<0) = 0; img(img>1) = 1;
        end
        
        if(showFigs)
            o = round(newOrigin);
            figure; set(gcf,'Name',[fileNameList{ii}]);
            subplot(1,3,1); imagesc(flipud(squeeze(img(:,:,o(3)))')); axis image; colormap gray;
            subplot(1,3,2); imagesc(flipud(squeeze(img(:,o(2),:))')); axis image; colormap gray;
            subplot(1,3,3); imagesc(flipud(squeeze(img(o(1),:,:))')); axis image; colormap gray;
            pause(0.1);
        end
        nans = isnan(img);
        numSamples(~nans) = numSamples(~nans)+weights(ii);
        img(nans) = 0;
        
        outNifti{ii} = img;
    end
end
% Rescale based on the number of samples at each voxel

for ii = 1:numImages
    % rescale to 15 bits (0-32767)
    img = outNifti{ii};
    img(img<0|isnan(img)) = 0;
    
    if ~isclassfile(ii)
        img = img-min(img(:));
        img = int16(img.*(32767/max(img(:))));
    end
    
    disp(['writing ',outFileName,'...']);
    dtiWriteNiftiWrapper(img, refXform, outFileName{ii}, [], ['Aligned to T1:' refDescrip]);

end

return;
