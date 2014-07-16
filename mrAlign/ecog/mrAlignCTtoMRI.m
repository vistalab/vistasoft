% Script to align a CT with a T1, written for ECoG.
% Written by Bob Dougherty, Michael Perry, and Andreas Rauschecker
% Wandell Lab
% June 2008
%

ctFile = 'ct.nii.gz';
t1File = 't1_aligned.nii.gz';

if(~exist(ctFile,'file'))
    % To build the ct, try this:
    ctDicomDir = 'dicom/axial';
    s = dicomLoadAllSeries(ctDicomDir,[],[],true);
    % the distance between slices is:
    d = sqrt(sum(diff(s.imagePosition').^2,2));  % maybe s.sliceLoc?
    slThick = mean(d);
    if(any(abs(d-slThick)>0.1)), 
        %error('inconsistent slice positions- fix manually.'); 
        % Reslice the CT to have a consistent slice thickness
        % Create a deformation field from the slice locations
        dims = double(s.dims);
        numZ = ceil(sum(d)./s.mmPerVox(3));
        cumInvD = cumsum([0,1./d']);
        zFov = sum(d);
        di = interp1(cumInvD, [1:numel(cumInvD)], linspace(cumInvD(1),cumInvD(end), numZ));  % is this right?  (di is the same as cumInvD for JB2)
        [xform.deformX,xform.deformY,xform.deformZ] = ndgrid([1:dims(1)], [1:dims(2)], di./max(di).*(dims(3)-1)+1);
        xform.inMat = eye(4);
        bb = [1 1 1; dims(1), dims(2), numel(di)];
        %defZmm = sum(d)./numel(di);
        newImg = mrAnatResliceSpm(double(s.imData), xform, bb, [1 1 1], 1, false);
        newXform = diag([1./s.mmPerVox(1) 1./s.mmPerVox(2) numZ./zFov 1]);
        newXform(1:3,4) = -size(newImg)./2;
        % Preserve the axis flips and invert it so that it is a qto_xyz
        newXform = inv(newXform).*sign(s.imToScanXform);
        ct = niftiGetStruct(int16(round(newImg)), newXform, 1, s.seriesDescription);
    else
        ct = niftiGetStruct(s.imData, s.imToScanXform, 1, s.seriesDescription);
        ct = niftiApplyCannonicalXform(ct);
        x = ct.qto_xyz;
        x(1:3,1:3) = diag([ct.pixdim(1) ct.pixdim(2) slThick]); 
        ct = niftiSetQto(ct, x);
    end
    ct.fname = 'ct.nii.gz';
    writeFileNifti(ct);
else
    ct = niftiRead(ctFile);
end

if(~exist(t1File,'file'))
    % To build the ct, try this:
    t1DicomDir = 'T1_DICOMS';
    s = dicomLoadAllSeries(t1DicomDir,[],[],true);
    t1 = niftiGetStruct(s.imData, s.imToScanXform, 1, s.seriesDescription);
    t1 = niftiApplyCannonicalXform(t1);
    % If the data aren't axial, then do a manual fix:
    % This will flip a coronal to an axial (check to be sure left-right is
    % correct!)
    t1 = niftiApplyCannonicalXform(t1,[1 0 0 0; 0 -1 0 0; 0 0 1 0; 0 0 0 1]);  % [left-right(?); ant-post; sup-inf; ?]
    % figure; img2 = makeMontage(t1.data); imagesc(img2); colormap gray
    t1.fname = 't1.nii.gz';
    writeFileNifti(t1);
    
else
    t1 = niftiRead(t1File);
    t1 = niftiApplyCannonicalXform(t1);
end

% Run this to manually set the ac-pc alignment
%mrAnatSetNiftiXform(t1File);
%t1 = niftiRead(t1File);

% CT slice thickness is wrong in the DICOM header. Header said 1.25, but it
% is actually 1.0. Maybe the slices overlap? Use SliceLocation field to see
% how far apart the slices actually are. (e.g. try diff(s.sliceLoc))
% x = ct.qto_xyz;
% x(1:3,1:3) = diag([ct.pixdim(1) ct.pixdim(2) 1.25]);  % you can get third dimension from diff(s.sliceLoc)
% ct = niftiSetQto(ct, x);
% ct.data = ct.data(:,:,1:28);  % this would be to keep only some slices (1-28)

% To align the T1
if(~all(t1.pixdim==t1.pixdim(1)))
    xform = diag([1./t1.pixdim 1]);
    xform(1:3,4) = t1.dim(1:3)/2;
    bb = mrAnatXformCoords(inv(xform),[0 0 0;t1.dim(1:3)]);
    [t1_resamp,newXform] = mrAnatResliceSpm(double(t1.data), xform, bb, [1 1 1]);
    t1_resamp(t1_resamp<0) = 0;
    t1_resamp = t1_resamp./max(t1_resamp(:));
    t1_resamp = int16(round(t1_resamp.*double(intmax('int16'))));
    t1 = niftiGetStruct(t1_resamp, newXform, 1, 't1 resampled');
    t1.fname = 't1_aligned.nii.gz';
    writeFileNifti(t1);
end

% To align the CT
% If the CT seems to be warped, you can try setting this unwarp flag to
% true. Doing so will allow a full 12-param affine alignment rather than
% the default 6-param rigid body.
unwarpCt = false;
ct = niftiApplyCannonicalXform(ct,[-1 0 0 0; 0 -1 0 0; 0 0 1 0; 0 0 0 1]);  % this line might help if you get a gray image instead of a CT, but you might have to change some numbers
xform = dtiRawAlignToT1(ct, t1, 'acpcXform', [], [], 1, unwarpCt);
ct.fname = 'ct_aligned.nii.gz';
ct = niftiSetQto(ct,xform);
writeFileNifti(ct);

bb = mrAnatXformCoords(t1.qto_xyz,[1 1 1; t1.dim(1:3)]);
ct_resamp = mrAnatResliceSpm(double(ct.data), inv(xform), bb, t1.pixdim(1:3));
ct_aligned = niftiGetStruct(single(ct_resamp), t1.qto_xyz, 1, 'ct aligned to t1');
ct_aligned.fname = 'ct_aligned.nii.gz';
writeFileNifti(ct_aligned);

% to check the alignment, make a montage of how well they overlap
r = mrAnatHistogramClip(double(t1.data),0.4,0.98);
g = r; b = r;
c = mrAnatHistogramClip(ct_resamp,0.4,0.98);
m = c>0.5;
r(m) = 0.5*c(m) + 0.5*r(m);
sl = [35:2:size(r,3)-35];
rgbIm = makeMontage3(r,g,b,sl,1);
imwrite(rgbIm,'ct_t1_align.png');

%% To regenerate the gray matter segmentation, run the following:
classNi = niftiRead('t1_class_gray_electrodes.nii.gz');
% left hemisphere
class = readClassFile(classNi,0,0,'left');
[nodes,edges,classData] = mrgGrowGray(class,2);
lGM = classData.data==classData.type.gray;
% right hemisphere
class = readClassFile(classNi,0,0,'right');
[nodes,edges,classData] = mrgGrowGray(class,2);
rGM = classData.data==classData.type.gray;

% you may need to flip some dimensions to get the correct orientation
lGM = permute(flipdim(flipdim(lGM,2),1),[3 1 2]);
rGM = permute(flipdim(flipdim(rGM,2),1),[3 1 2]);
l = mrGrayGetLabels;
classNi.data(lGM) = l.leftGray;
classNi.data(rGM) = l.rightGray;

classNi.fname = 't1_class_gray_electrodes.nii.gz';
writeFileNifti(classNi);

