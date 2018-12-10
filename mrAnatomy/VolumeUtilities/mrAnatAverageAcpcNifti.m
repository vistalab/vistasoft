function [outImg] = mrAnatAverageAcpcNifti(fileNameList, outFileName, alignLandmarks, newMmPerVox, weights, bb, showFigs, clipVals)
%
% outImg = mrAnatAverageAcpcNifti(fileNameList, outFileName, [alignLandmarks=[]], [newMmPerVox=[1 1 1]], [weights=ones(size(fileNameList))], [bb=[-90,90; -126,90; -72,108]'], [showFigs=true], [clipVals])
%
% Reslices the first NIFTI file to ac-pc space at newMmPerVox resolution
% (default = 1x1x1mm).  It then aligns all the rest of the files to that
% one and averages them all together.
%
% INPUTS:
%  fileNameList - cell array of nifti files. It can also be a directory,
%   in which case all nifti files in that directory will be included, or it
%   can be a more specific wildcard string, such as '/some/dir/t1_*.nii.gz'.
%
%  outFileName - 
%
%
% You can specify the ac-pc landmarks as a 3x3 matrix of the form:
%
%     [ acX, acY, acZ; pcX, pcY, pcZ; midSagX, midSagY, midSagZ ]
%
% ac is the anterior commissure, pc is the posterior commissure, and midSag
% is another point in the mid-sagittal plane that is somewhat distant from
% the ac-pc line. These 3 points define the rotation/translation into ac-pc
% space. If the ac is properly set in the image header, then you can just
% pass in the pc and midSag coords, specified as the offset from the ac.
%
% Parameters
%   If alignLandmarks==[], then a GUI is launched to allow you to set them,
%   using the first image as the reference.
%   If alignLandmarks==false, then the qform matrix from the first image is
%   assumed to put it into ac-pc space and this is used.
%
%   Alternatively, you can pass in a filename for the alignLandmarks. This
%   is assumed to be an image file and that image will be used as the
%   reference. If it is ac-pc aligned and reasonably similar to the input
%   images, then this will work well.
%
%   weights - specifies the weighting factor to be applied to each of the
%   input images (fileNameList). This is useful when averaging images with
%   different SNRs, e.g. when you have 3 images with SENSE/ASSET reduction
%   factors of 0 (no SENSE), 1.5, and 2.0, you might specify weights of
%   [1.0 0.82 0.7].
%
% RETURNS 
%  outImage - a montage of the final average volume, useful for visual
% inspection of the results.
%
% REQUIRES:
%  * spm2 or spm5 or spm8? tools (eg. /usr/local/matlab/toolbox/mri/spm5_r2008)
%
% HISTORY:
% 2006.07.17 RFD (bob@white.stanford.edu) wrote it, based on mrAnatAverageAcpcAnalyze
% 2006.07.2? RFD: added 3-axis viewer for specifying ac-pc landmarks.
% 2006.08.04 RFD: added option to pass a template image (ie. the
% anat.img from a dt6 file) instead of alignLandmarks.
% 2011.01.19 LMP commented-out the check for file extension, which was adding
% characters (.nii.gz) when the case was not .nii. (li 122-126)
%

%% Initialize parameters

% If no fileNameList, get one
if (~exist('fileNameList','var') || isempty(fileNameList))
    [f,p] = uigetfile({'*.nii.gz','NIFTI';'*.*', 'All Files (*.*)'}, 'Select NIFTI files...', 'MultiSelect', 'on');
    if(isnumeric(f)) disp('User canceled.'); return; end
    if(iscell(f))
        for ii=1:length(f)
            fileNameList{ii} = fullfile(p,f{ii});
        end
    else
        fileNameList = {fullfile(p,f)};
    end
end

% At this point we have fileNameList for sure.  If it is just a string, we
% rebuild it to our liking as a cell array.
if(ischar(fileNameList))
    % Parse the '*' if the string allows multiple files with a common base
    % name.
    if(isempty(strfind(fileNameList,'*')))
        d = cat(1, dir(fullfile(fileNameList,'*.nii.gz')), dir(fullfile(fileNameList,'*.nii')), dir(fileNameList));
    else
        d = dir(fileNameList);
        fileNameList = fileparts(fileNameList);
    end
    % Build the cell array
    for ii=1:length(d)
        tmp{ii} = fullfile(mrvDirup(fileNameList),d(ii).name);
    end
    fileNameList = tmp;
end

% Choose the output file if not there already
if(~exist('outFileName','var') || isempty(outFileName))
    [p,f] = fileparts(fileNameList{1});
    outFileName = fullfile(p,'average.nii.gz');
    [f,p] = uiputfile('*.nii.gz','Select output file...',outFileName);
    if(isnumeric(f)) disp('User canceled.'); return; end
    outFileName = fullfile(p,f);
end

% Default the resolution
if (~exist('newMmPerVox','var') || isempty(newMmPerVox))
    newMmPerVox = [1 1 1];
    mmSentIn = false;
else
    mmSentIn = true;
end

if(~exist('showFigs','var') || isempty(showFigs)), showFigs = true; end

if(~exist('alignLandmarks','var')), alignLandmarks = []; end

if(~exist('weights','var') || isempty(weights)), weights = ones(size(fileNameList)); end

% Hopefully near the value if in mm.  
if(~exist('bb','var') || isempty(bb))
    % Bounding box, in physical space (ie. mm from the origin, which should be
    % at or near the AC).
    bb = [-90,90; -126,90; -72,108]';
end

if (~exist('clipVals','var')), clipVals = []; end

%% Start processing with SPM routines

% from spm_bsplins:
% d(1:3) - degree of B-spline (from 0 to 7) along different dimensions
% d(4:6) - 1/0 to indicate wrapping along the dimensions
% not sure what wrapping is, but '7' is the highest quality (but slowest).
bSplineParams = [7 7 7 0 0 0];

% We explicitly initialize the spm_defaults global here, and ensure that
% the analyze_flip option is turned off. (Our analyze files are never
% right-left reversed!)
spm_defaults;
defaults.analyze.flip = 0; %#ok<STRNU>

if(isstruct(fileNameList))
    % assume we were passed a nifti file
    ni = fileNameList;
    numImages = 1;
else
    for ii=1:length(fileNameList)
        if(~exist(fileNameList{ii},'file')), error([fileNameList{ii} ' does not exist!']); end
    end
    % Load the first image (the reference)
    ni = niftiRead(fileNameList{1});
    ni = niftiApplyCannonicalXform(ni);
    numImages = length(fileNameList);
end

refDescrip = ni.descrip;

%% Clip, but not sure why that is done here.  Maybe for alignment?
if(isempty(clipVals))
    clipVals = repmat([0.4 0.98],numImages,1);
end

refImg = mrAnatHistogramClip(double(ni.data(:,:,:,1)), clipVals(1,1), clipVals(1,2));
%[refImg, lc, uc] = mrAnatHistogramClipOptimal(refImg, 99);
%fprintf('\nClipped reference image at [%0.1f, %0.1f].\n', lc,uc);

% Popup a GUI that lets you specify the ACPC positions
if(isempty(alignLandmarks))
    nii.img = refImg;
    nii.hdr.dime.pixdim = [1 ni.pixdim 1 1 1 1];
    nii.hdr.dime.datatype = 64;
    nii.hdr.dime.dim = [3 size(nii.img) 1 1 1 1];
    nii.hdr.hist.originator = [round(ni.qto_ijk(1:3,:)*[0 0 0 1]')'+1 128 0];
    h = figure('unit','normal','pos', [0.18 0.08 0.25 0.85],'name','Set AC-PC landmarks');
    if ~isnumeric(h)
        % In Matlab 2014b and up the figure handle is defined as an object.
        % This new definition is not compatible with older versions of
        % Matlab that treat the handle as a number.
        h = h.Number;
    end
    opt.setarea = [0.05 0.15 0.9 0.8];
    opt.usecolorbar = 0;
    %     opt.usestretch = 0;
    opt.usestretch = 1;
    opt.command = 'init';
    view_nii(h, nii, opt);
    hstr = num2str(h);
    cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''ac'',p);set(gcbo,''String'',[''AC=['' num2str(p) '']'']);'];
    b1 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set AC','Position',[20 30 150 30],'Callback',cb);
    cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''pc'',p);set(gcbo,''String'',[''PC=['' num2str(p) '']'']);'];
    b2 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set PC','Position',[190 30 150 30],'Callback',cb);
    cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''ms'',p);set(gcbo,''String'',[''MidSag=['' num2str(p) '']'']);'];
    b3 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set MidSag','Position',[360 30 150 30],'Callback',cb);
    cb = ['setappdata(' hstr ',''done'',1);'];
    b4 = uicontrol(h, 'Style','pushbutton','Visible','on','String','FINISH','Position',[530 30 80 30],'Callback',cb);
    done = false;
    while(~done)
        d = getappdata(h);
        if(isfield(d,'ac')&&isfield(d,'pc')&&isfield(d,'ms')&&isfield(d,'done')&&d.done==1)
            done = true;
            alignLandmarks = [d.ac; d.pc; d.ms]-0.5
            % Account for the image-to-scanner xform
            %alignLandmarks = sign(ni.qto_xyz(1:3,1:3))*alignLandmarks;
        end
        pause(.1);
    end
    close(h);
else
    % alignLandmarks is not empty- check for special cases
    if(ischar(alignLandmarks))
        % Assume that alignLandmarks is an image to align with. For now,
        % we assume that it is a dt6 file or a nifti file.
        % TODO: allow an analyze or nifti image file to be passed.
        [p,f,e] = fileparts(alignLandmarks);
        disp(['Aligning reference image to the template image in ' f '...']);
        if(strcmpi(e,'.nii')||strcmpi(e,'.gz'))
            tmp = niftiRead(alignLandmarks);
            img = tmp.data;
            acpcXform = tmp.qto_xyz;
            mmPerVox = tmp.pixdim([1:3]);
            clear tmp;
        elseif(strcmpi(e,'.img')||strcmpi(e,'.hdr'))
            [img,mmPerVox,tmp] = loadAnalyze(alignLandmarks);
            acpcXform = tmp.mat;
            clear tmp;
        elseif(strcmpi(e,'.mat'))
            tmp = load(alignLandmarks,'anat');
            img = tmp.anat.img;
            acpcXform = tmp.anat.xformToAcPc;
            mmPerVox = tmp.anat.mmPerVox;
            clear tmp;
        else
            error('Unrecognized template format.');
        end
        
        if(~all(newMmPerVox==mmPerVox) && ~mmSentIn)
            newMmPerVox = mmPerVox;
            warning(sprintf('Overriding specificed mmPerVox to match that of the specified template image (%0.1f %0.1f %0.1f).',newMmPerVox(1),newMmPerVox(2),newMmPerVox(3)));
        end
        img(isnan(img)) = 0;
        Vref.uint8 = uint8(round(mrAnatHistogramClip(double(img), clipVals(1,1), clipVals(1,2)).*255+.5));
        Vref.mat = acpcXform;
        refImg(isnan(refImg)) = 0;
        Vin.uint8 = uint8(round(refImg.*255+0.5));
        Vin.mat = ni.qto_xyz;
        transRot = spm_coreg(Vref, Vin);
        xform = inv(Vin.mat)*spm_matrix(transRot(end,:));
        fprintf('Resampling reference to template image space...\n');
        [refImg,refXform] = mrAnatResliceSpm(refImg, xform, bb, newMmPerVox, bSplineParams, showFigs);
        alignLandmarks = [];
    elseif(numel(alignLandmarks)==1)
        % -1, 0, false, etc. means that we use the qform matrix from the first image.
        fprintf('Resampling reference image to acpc space...\n');
        [refImg,refXform] = mrAnatResliceSpm(refImg, ni.qto_ijk, bb, newMmPerVox, bSplineParams, showFigs);
        alignLandmarks = [];
    end
end

if(~isempty(alignLandmarks))
    if(size(alignLandmarks,1)==2)
        origin = ni.qto_ijk*[0 0 0 1]'-0.5;
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
    if(imX(1)<0), imX = -imX; end
    if(imY(2)<0), imY = -imY; end
    if(imZ(3)<0), imZ = -imZ; end
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
    tal2ref(1:3,4) = (origin + newMmPerVox/2)';
    
    % Resample it to 1x1x1
    disp('Resampling reference image to ac-pc space, isotropic voxels...');
    [refImg,refXform] = mrAnatResliceSpm(refImg, tal2ref, bb, newMmPerVox, bSplineParams, showFigs);
end

newOrigin = inv(refXform)*[0 0 0 1]'; newOrigin = newOrigin(1:3)'-newMmPerVox/2;
% Reclip in case the interpolation introduced out-of-range values
refImg(refImg<0|isnan(refImg)) = 0; refImg(refImg>1) = 1;
if(showFigs)
    o = round(newOrigin);
    figure; set(gcf,'Name',[ni.fname ' (ref)']);
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

for ii=1:numImages
    if(ii==1)
        startInd = 2;
    else
        startInd = 1;
        ni = niftiRead(fileNameList{ii});
        ni = niftiApplyCannonicalXform(ni);
    end
    
    if(isempty(ni.data)) error('NIFTI file error (%s)!',fileNameList{ii}); end
    %endInd = size(ni.data,4);
    endInd = min(2,size(ni.data,4));
    for jj=startInd:endInd
        fprintf('Aligning image %d of %s to reference image...\n',jj,fileNameList{ii});
        img = mrAnatHistogramClip(double(ni.data(:,:,:,jj)), clipVals(ii,1), clipVals(ii,2));
        img(isnan(img)) = 0;
        Vin.uint8 = uint8(round(img.*255));
        Vin.mat = ni.qto_xyz;
        transRot = spm_coreg(Vref, Vin);
        xform = inv(Vin.mat)*spm_matrix(transRot(end,:));
        fprintf('Resampling %s to reference image...\n',fileNameList{ii});
        [img,xform] = mrAnatResliceSpm(img, xform, bb, newMmPerVox, bSplineParams, showFigs);
        % Reclip in case the interpolation introduced out-of-range values
        img(img<0) = 0; img(img>1) = 1;
        if(showFigs)
            o = round(newOrigin);
            figure; set(gcf,'Name',[ni.fname]);
            subplot(1,3,1); imagesc(flipud(squeeze(img(:,:,o(3)))')); axis image; colormap gray;
            subplot(1,3,2); imagesc(flipud(squeeze(img(:,o(2),:))')); axis image; colormap gray;
            subplot(1,3,3); imagesc(flipud(squeeze(img(o(1),:,:))')); axis image; colormap gray;
            pause(0.1);
        end
        nans = isnan(img);
        numSamples(~nans) = numSamples(~nans)+weights(ii);
        img(nans) = 0;
        outImg = outImg+img.*weights(ii);
    end
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
    title('Average aligned.');
    pause(0.1);
end

% rescale to 15 bits (0-32767)
outImg(outImg<0|isnan(outImg)) = 0;
outImg = outImg-min(outImg(:));
outImg = int16(outImg.*(32767/max(outImg(:))));

disp(['writing ',outFileName,'...']);
dtiWriteNiftiWrapper(outImg, refXform, outFileName, [], ['AVERAGE:' refDescrip]);
if(nargout<1)
    clear outImg;
else
    outImg = makeMontage(outImg);
    outImg = uint8(round(double(outImg)./(32767/255)));
end

end
