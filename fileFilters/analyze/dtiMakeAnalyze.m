function [t1,b0] = dtiMakeAnalyze(b0PathName, t1PathName, t1AnalyzePathName, outPathName)
%
% [t1,b0] = dtiMakeAnalyze(b0PathName, t1PathName, t1AnalyzePathName, outPathName)
%
% Takes a set of images from a DTI sequence and saves them out as
% analyze-format files. It will also save out a transform matrix that will
% coregister the DTI images to another scan series (typically a T1 scan
% from the same session).
% Also, if the t1 analyze file is provided and includes a talairach file,
% the transform matrix will also include the affine component of the 
% talairach transform. 
%
% HISTORY:
% 2003.08.?? RFD (bob@white.stanford.edu) wrote it.

useManual = false;

if ~exist('b0PathName','var') | isempty(b0PathName)
   [f, p] = uigetfile({'*.001','I-files (*.001)';'*.*','All files'}, 'Select one of the B0 I-files...');
   if(isnumeric(f)) error('Need a B0 file to continue...'); end
   b0PathName = fullfile(p, f);
   disp(b0PathName);
end
b0.fname = b0PathName;

if ~exist('t1PathName','var') | isempty(t1PathName)
   [f, p] = uigetfile({'*.001','I-files (*.001)';'*.*','All files'}, 'Select one of the T1 I-files...');
   if(isnumeric(f)) error('Need a T1 file to continue...'); end
   t1PathName = fullfile(p, f);
   disp(t1PathName);
end
t1.fname = t1PathName;

if ~exist('t1AnalyzePathName','var') | isempty(t1AnalyzePathName)
   [f, p] = uigetfile({'*.hdr','Analyze files (*.hdr)';'*.*','All files'},...
       'Select the T1 Analyze file...');
   if(isnumeric(f)) error('Need a T1 file to continue...'); end
   t1AnalyzePathName = fullfile(p, f);
   disp(t1AnalyzePathName);
end
t1.analyzeFname = t1AnalyzePathName;
[p,f,e] = fileparts(t1AnalyzePathName);
t1.analyzeBaseFname = fullfile(p,f);

% Compute the transform that would happen if we made this into an analyze
% format file using our code, which imposes a particular data orientation
% (axial, neurological convention). Note that the transofrm returned here
% should consits of just flips and mirror-reversals. There will be no
% scales, skews or translations.
[b0.cannonical, b0.baseFname, b0.mmPerVox, b0.imDim, b0.notes] = computeCannonicalXformFromIfile(b0.fname);
[t1.cannonical, t1.baseFname, t1.mmPerVox, t1.imDim, t1.notes] = computeCannonicalXformFromIfile(t1.fname);

if(~exist('outPathName','var') | isempty(outPathName))
    outPathName = fullfile(fileparts(fileparts(b0.baseFname)), 'dti_analyses');
end
if(~exist('outPathName','dir'))
    [p,f,e] = fileparts(outPathName);
    mkdir(p, [f e]);
end

swapXY = [0 1 0 0; 1 0 0 0; 0 0 1 0; 0 0 0 1];

t1.talairach = load([t1.analyzeBaseFname '_talairach']);
% We also want a transform that will go into ac-pc space (ie.
% Talairach, but without any scaling). We can compute that by
% adjusting the scale factors in the talairach transform.
t1.talXform = t1.talairach.vol2Tal.transRot'*swapXY;
p = spm_imatrix(t1.talXform);
% We also have to rescale the translations.
scaleDiff = t1.mmPerVox./p(7:9);
p(1:3) = p(1:3).*scaleDiff;
p(7:9) = t1.mmPerVox;
t1.acpcXform = spm_matrix(p);

% Now compute the transform from the standard scanner coordinate space
% to the image coordinate space (eg. scanner2img*[X Y Z 1]' will convert
% the X Y Z scanner coords to indices into the img.)
b0.scanner2img = XformFromIfile(b0.baseFname,'volume');
t1.scanner2img = XformFromIfile(t1.baseFname,'volume');

% create and save the T1 analyze file .mat transform, computed from the
% talairach file.
t1Tal = t1.talairach.vol2Tal.transRot'*swapXY;
M_acpc = t1.acpcXform;
M_tal = t1.talXform;
M = t1.talXform;
save(t1.analyzeBaseFname, 'M', 'M_tal', 'M_acpc');
% Also, make sure the T1 .hdr origin is set to the AC (Talairach 0,0,0)
t1.origin = inv(t1Tal)*[0,0,0,1]';
t1.origin = t1.origin(1:3)';
[dim vox scale type offset origin descrip] = spm_hread(t1.analyzeBaseFname);
spm_hwrite(t1.analyzeBaseFname, dim, vox, scale, type, offset, t1.origin, descrip);

% We use a pre-multiply convention (newCoords = M*oldCoords), so read 
% the matrix transforms from right to left:
% 1. undo the b0 cannonical xform (inv(b0.cannonical))
% 2. b0 image space o scanner space (inv(b0.scanner2img))
% 3. scanner space to t1 image space (t1.scanner2img)
% 4. t1 image space to cannonical x-formed t1 image space(t1.cannonical)
% 5. t1 cannonical image space to t1 standard space (t1Hdr.mat)
%
% Note: the SPM convention seems to be to swap X and Y, so we have to undo
% that swap from the t1 transforms when computing ours. Then, we swap our
% transform before saving it. Why? Because it makes everything work. But, I
% really don't understand it fully. Maybe the swap is happening in myCinterp3 
% (called from dtiGetSlice)?
M = t1.cannonical * swapXY * t1.scanner2img * inv(b0.scanner2img) * b0.cannonical;
M_tal = t1Tal * M;
M = M*swapXY;
M_tal = M_tal*swapXY;
b0.M = M;
b0.M_tal = M_tal;
% Set the origin to the AC (Talairach 0,0,0)
b0.origin = inv(b0.M_tal)*[0,0,0,1]';
b0.origin = b0.origin(1:3)';

% Build B0, FA and vector images
[b0.img, fa, add, ci, meanDiff, maxEig, medEig, minEig, maxVec] = ...
    dtiLoadTensorcalc(fullfile(fileparts(b0.baseFname), 'Tensor.float.001'));
b0.img = permute(b0.img, [2,1,3]); % x and y are permuted in the Tensor.float file
[b0.imgCannonical, mmPerVoxNew] = applyCannonicalXform(b0.img, b0.cannonical, b0.mmPerVox);
hdr = saveAnalyze(b0.imgCannonical, fullfile(outPathName,'B0'), mmPerVoxNew, b0.notes, b0.origin);
[img, mmPerVoxNew] = applyCannonicalXform(permute(fa*1000, [2,1,3]), b0.cannonical, b0.mmPerVox);
hdr = saveAnalyze(img, fullfile(outPathName,'FA'), mmPerVoxNew, b0.notes, b0.origin);
% The first two dims will get permuted when we write the data out to
% the analyze file (to put them in standard analyze axial form). But,
% we need to permute them here because tensorcalc permuted them
% relative to the original Ifiles.
maxVec = permute(maxVec,[2 1 3 4]);
% Since we just permuted voxel coordinates, we should also swap X and Y, 
% but it turns out that the tensorcalc convention makes X 
% anterior-posterior and Y left-right, but we want them to be the other 
% way to follow Talairach naming convention. So, we leave them as is.
hdr = saveAnalyze(applyCannonicalXform(maxVec(:,:,:,1), b0.cannonical, b0.mmPerVox), fullfile(outPathName,'vecX'), mmPerVoxNew, b0.notes, b0.origin);
hdr = saveAnalyze(applyCannonicalXform(maxVec(:,:,:,2), b0.cannonical, b0.mmPerVox), fullfile(outPathName,'vecY'), mmPerVoxNew, b0.notes, b0.origin);
hdr = saveAnalyze(applyCannonicalXform(maxVec(:,:,:,3), b0.cannonical, b0.mmPerVox), fullfile(outPathName,'vecZ'), mmPerVoxNew, b0.notes, b0.origin);

% Compute and show test images
% t1Hdr should contain the Talairach xform that we just saved.
[t1Img, t1Mm, t1Hdr] = loadAnalyze(t1.analyzeFname);
%t1.img = makeCubeIfiles(t1.baseFname, t1.imDim(1:2), [1:t1.imDim(3)]);

imDims = [-70,70;-120,80;-60,80]';
slice = [0,0,0];

done = false;
newM = b0.M_tal;
while(~done & useManual)
    M = t1Hdr.mat;
    img = t1Img;
    fig = 90;
    [Xsl,x,y,z] = dtiGetSlice(M, img, 3, slice(3), imDims);
    figure(fig); h(1) = subplot(2,3,1); imagesc(imDims(:,1), imDims(:,2), Xsl); colormap(gray); axis equal tight xy;
    [Ysl,x,y,z] = dtiGetSlice(M, img, 2, slice(2), imDims);
    figure(fig); h(2) = subplot(2,3,2); imagesc(imDims(:,3), imDims(:,1), Ysl); colormap(gray); axis equal tight xy;
    [Zsl,x,y,z] = dtiGetSlice(M, img, 1, slice(1), imDims);
    figure(fig); h(3) = subplot(2,3,3); imagesc(imDims(:,3), imDims(:,2), Zsl); colormap(gray); axis equal tight xy;
    
    t1Xslice = Xsl; t1Yslice = Ysl; t1Zslice = Zsl;
    
    slice = [0,0,0];
    M = newM;
    %This XY swap business is why we have to do this permute here.
    img = b0.imgCannonical; 
    [Xsl,x,y,z] = dtiGetSlice(M, img, 3, slice(3), imDims);
    figure(fig); h(4) = subplot(2,3,4); imagesc(imDims(:,1), imDims(:,2), Xsl); colormap(gray); axis equal tight xy;
    [Ysl,x,y,z] = dtiGetSlice(M, img, 2, slice(2), imDims);
    figure(fig); h(5) = subplot(2,3,5); imagesc(imDims(:,3), imDims(:,1), Ysl); colormap(gray); axis equal tight xy;
    [Zsl,x,y,z] = dtiGetSlice(M, img, 1, slice(1), imDims);
    figure(fig); h(6) = subplot(2,3,6); imagesc(imDims(:,3), imDims(:,2), Zsl); colormap(gray); axis equal tight xy;
    
    b0Xslice = Xsl; b0Yslice = Ysl; b0Zslice = Zsl;
    
    disp('select corresponding points on each B0 and T1 image.');
    donePoints = false;
    ptList = [];
    while(~donePoints)
        for(ii=1:6)
            axes(h(ii));
            title('current');
            p = ginput(1);
            title('');
            if(isempty(p))
                donePoints = true;
                break;
            end
            hold on; plot(p(:,1), p(:,2), 'xy'); hold off;
            pts(ii,:) = p;
        end
        % Only add this set if it is complete
        if(size(pts,1)==6)
            if(isempty(ptList)) ptList = pts;
            else ptList = [ptList; pts]; end
        end
    end
    
    % Adjust newM given points...
    adjustment = eye(4);

    fig = 92;
    t1mv = max([t1Xslice(:); t1Yslice(:); t1Zslice(:)]);
    b0mv = max([b0Xslice(:); b0Yslice(:); b0Zslice(:)]);
    Xsl(:,:,1) = t1Xslice./t1mv.*.5 + b0Xslice./b0mv.*.5;
    Xsl(:,:,2) = t1Xslice./t1mv.*.5; Xsl(:,:,3) = t1Xslice./t1mv.*.5;
    Ysl(:,:,1) = t1Yslice./t1mv.*.5 + b0Yslice./b0mv.*.5;
    Ysl(:,:,2) = t1Yslice./t1mv.*.5; Ysl(:,:,3) = t1Yslice./t1mv.*.5;
    Zsl(:,:,1) = t1Zslice./t1mv.*.5 + b0Zslice./b0mv.*.5;
    Zsl(:,:,2) = t1Zslice./t1mv.*.5; Zsl(:,:,3) = t1Zslice./t1mv.*.5;
    figure(fig); subplot(2,2,1); imagesc(imDims(:,1), imDims(:,2), Xsl); colormap gray; axis equal tight xy;
    figure(fig); subplot(2,2,2); imagesc(imDims(:,3), imDims(:,1), Ysl); colormap(gray); axis equal tight xy;
    figure(fig); subplot(2,2,3); imagesc(imDims(:,3), imDims(:,2), Zsl); colormap(gray); axis equal tight xy;
    
    bn = questdlg('Is this good?', ...
                  'Continue manual registration...', ...
                  'Yes','No','Abort','No');
    if(strcmpi(bn, 'Yes')) done = true; end
    if(strcmpi(bn, 'Abort')) done = true; useManual = false; end    
end

% Save all the transform files
if(useManual)
    M = adjustment*b0.M;
    M_tal = adjustment*b0.M_tal;
else
    slice = [0,0,0];
    img = t1Img; 
    [Xsl,x,y,z] = dtiGetSlice(t1Hdr.mat, img, 3, slice(3), imDims);
    [Ysl,x,y,z] = dtiGetSlice(t1Hdr.mat, img, 2, slice(2), imDims);
    [Zsl,x,y,z] = dtiGetSlice(t1Hdr.mat, img, 1, slice(1), imDims);
    t1Xslice = Xsl; t1Yslice = Ysl; t1Zslice = Zsl;
    
    img = b0.imgCannonical; 
    [Xsl,x,y,z] = dtiGetSlice(b0.M_tal, img, 3, slice(3), imDims);
    [Ysl,x,y,z] = dtiGetSlice(b0.M_tal, img, 2, slice(2), imDims);
    [Zsl,x,y,z] = dtiGetSlice(b0.M_tal, img, 1, slice(1), imDims);
    b0Xslice = Xsl; b0Yslice = Ysl; b0Zslice = Zsl;

    fig = figure;
    t1mv = max([t1Xslice(:); t1Yslice(:); t1Zslice(:)]);
    b0mv = max([b0Xslice(:); b0Yslice(:); b0Zslice(:)]);
    Xsl(:,:,1) = t1Xslice./t1mv.*.5 + b0Xslice./b0mv.*.5;
    Xsl(:,:,2) = t1Xslice./t1mv.*.5; Xsl(:,:,3) = t1Xslice./t1mv.*.5;
    Ysl(:,:,1) = t1Yslice./t1mv.*.5 + b0Yslice./b0mv.*.5;
    Ysl(:,:,2) = t1Yslice./t1mv.*.5; Ysl(:,:,3) = t1Yslice./t1mv.*.5;
    Zsl(:,:,1) = t1Zslice./t1mv.*.5 + b0Zslice./b0mv.*.5;
    Zsl(:,:,2) = t1Zslice./t1mv.*.5; Zsl(:,:,3) = t1Zslice./t1mv.*.5;
    figure(fig); subplot(2,2,1); imagesc(imDims(:,1), imDims(:,2), Xsl); colormap gray; axis equal tight xy;
    figure(fig); subplot(2,2,2); imagesc(imDims(:,3), imDims(:,1), Ysl); colormap(gray); axis equal tight xy;
    figure(fig); subplot(2,2,3); imagesc(imDims(:,3), imDims(:,2), Zsl); colormap(gray); axis equal tight xy;

    M = b0.M;
    M_tal = b0.M_tal;
end
save(fullfile(outPathName,'B0'), 'M', 'M_tal');
save(fullfile(outPathName,'FA'), 'M', 'M_tal');
save(fullfile(outPathName,'vecX'), 'M', 'M_tal');
save(fullfile(outPathName,'vecY'), 'M', 'M_tal');
save(fullfile(outPathName,'vecZ'), 'M', 'M_tal');

% Now build and save the dt6 data
[eigVec, eigVal] = dtiLoadTensor(fullfile(fileparts(b0.baseFname), 'Vectors.float.'));
dt6_tmp = dtiRebuildTensor(eigVec, eigVal);
dt6_tmp = permute(dt6_tmp,[2 1 3 4]);
for(ii=1:6)
    dt6(:,:,:,ii) = applyCannonicalXform(dt6_tmp(:,:,:,ii), b0.cannonical, b0.mmPerVox);
end
clear dt6_tmp;
mmPerVox = mmPerVoxNew;
notes = b0.notes;
xformToAnat = M;
xformToTal = M_tal;
b0 = int16(round(b0.imgCannonical));
anat.img = int16(t1Img);
anat.mmPerVox = t1Mm;
anat.xformToTal = t1Hdr.mat;
save(fullfile(outPathName,'dt6'), 'dt6', 'mmPerVox', 'notes', 'xformToAnat', 'xformToTal', 'b0', 'anat');

return;


[subjects, baseDir] = getSubjects('dc', 'c', 'dtiSubjectsCortexPaper.txt');
%baseDir = pwd;
d = dir(baseDir);
subjects = {};
for(ii=1:length(d))
    if(~strcmp(d(ii).name,'.') & ~strcmp(d(ii).name,'..') ...
        & (strcmp(d(ii).name(3),'0') | strcmp(d(ii).name(4),'0')))
        subjects{end+1} = d(ii).name;
    end
end
for(ii=1:length(subjects))
    sub = subjects{ii};
    base = fullfile(baseDir,sub);
    try
    dtiMakeAnalyze(fullfile(base,'dti','B0.001'),...
        fullfile(base,'t1','spgr1','I.001'), ...
        fullfile(base,'t1',[sub '_t1anat_avg']));
    catch
        disp(['skipped subject ' sub]);
    end
end
