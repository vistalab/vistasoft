function [xform, mmPerVox, voxDim] = affineScanner2Pixels(anIfile, crop)
% 
% [xform, mmPerVox, voxDim] = affineScanner2Pixels(anIfile, [crop])
%
% Determines the affine 4x4 transform that transforms
% scanner coordinates to 3D pixel coordinates (pre-multiply convention).
%
%  INPUTS:
%    anIfile: the first image file (GE I-file or DICOM file)
%    crop:   [top left X, Y bottom right X, Y] cropping values.
%		  Useful when dealing with inplane Ifiles.
%
%  HISTORY:  
% 2002.07.22 Sunjay Lad (slad@stanford.edu) - wrote it
% 2003.07.15 RFD (bob@white.stanford.edu) - major overhaul
% 2004.01.24 Junjie: Use readIfileHeader instead of GE_readHeader to
% accomodate DICOM formats. However, I think this mfile is retired and
% replaced by computeCannonicalXformFromIfile.m
% 2005.10.21 ras: imported into mrVista2 repository as
% affineScanner2Pixels.
if(~exist('anIfile', 'var') | isempty(anIfile))
  help(mfilename);
  return;
end

if(~exist('crop', 'var'))
  crop = [];
end

allIfileNames = getIfileNames(anIfile);
nSlices = length(allIfileNames);
firstSlice = allIfileNames{1};
lastSlice = allIfileNames{end};

% Extract the header info from the first and last slices 
[su_hdr1, ex_hdr1, se_hdr1, im_hdr1] = readIfileHeader(firstSlice);
[su_hdr2, ex_hdr2, se_hdr2, im_hdr2] = readIfileHeader(lastSlice);
voxDim = double([im_hdr1.imatrix_X im_hdr1.imatrix_Y nSlices]);

% GE scanner coords : trc=top-right-corner, brc=bottom-right-corner, 
% tlc=top-left-corner. All coords are GE's RAS- in mm, with axis order R/L, 
% A/P, S/I with right=positive, anterior=positive, superior=positive
trc1 = double([im_hdr1.trhc_R, im_hdr1.trhc_A, im_hdr1.trhc_S]);
brc1 = double([im_hdr1.brhc_R, im_hdr1.brhc_A, im_hdr1.brhc_S]);
tlc1 = double([im_hdr1.tlhc_R, im_hdr1.tlhc_A, im_hdr1.tlhc_S]);
trc2 = double([im_hdr2.trhc_R, im_hdr2.trhc_A, im_hdr2.trhc_S]);
tlc2 = double([im_hdr2.tlhc_R, im_hdr2.tlhc_A, im_hdr2.tlhc_S]);
brc2 = double([im_hdr2.brhc_R, im_hdr2.brhc_A, im_hdr2.brhc_S]);

% We also need blc:
blc1 = trc1 + (tlc1-trc1) + (brc1-trc1);
blc2 = trc2 + (tlc2-trc2) + (brc2-trc2);

% We use nSlices-1 because each pixel coordinate is taken 
% to be at the center of the slice along the z-axis)
% Note: following might be necessary if there were spacing between slices
% sliceVol = (nSlices - 1)*(1 + (im_hdr1.scanspacing/im_hdr1.slthick))
pixDim = double([im_hdr1.imatrix_X im_hdr1.imatrix_Y nSlices-1]);
if(isempty(crop))
  pix_tlc1 = [0, 0, 0];
  pix_trc1 = double([0, pixDim(2), 0]);
  pix_blc1 = double([pixDim(1), 0, 0]);
  pix_tlc2 = double([0, 0, pixDim(3)]);
  
  %pix_brc1 = double([pixDim(1), pixDim(2), 0]);
  %pix_trc2 = double([pixDim(1), 0, pixDim(3)]);
  %pix_blc2 = double([0, pixDim(2), pixDim(3)]);
  %pix_brc2 = double([pixDim(1) pixDim(2) pixDim(3)]);
else
  % Apply "cropping" here before computing xform (using negative coords) 
  pix_tlc1 = double([-crop(1, 2),      -crop(1, 1),      0]);
  pix_trc1 = double([-crop(1, 2),      pixDim(2)-crop(1, 1), 0]);
  pix_blc1 = double([pixDim(1)-crop(1, 2), -crop(1, 1),      0]);
  pix_tlc2 = double([-crop(1, 2),      -crop(1, 1),      pixDim(3)]);
end

% GE scanner coords for all 4 reference points (4x4 matrix)
%scanCoords = cat(1, tlc1, trc1, brc1, blc1, blc2, brc2, trc2, tlc2)';
scanCoords = cat(1, tlc1, trc1, blc1, tlc2)';

% Pixel coords for all 4 slices (4x4 matrix)
%pixCoords = cat(1, pix_tlc1, pix_trc1, pix_brc1, pix_blc1, pix_blc2, pix_brc2, pix_trc2, pix_tlc2)';
pixCoords = cat(1, pix_tlc1, pix_trc1, pix_blc1, pix_tlc2)';

% 4x4 transform from GE scanner coords -> pixel coords
xform = [pixCoords; ones(1, size(pixCoords, 2))] / [scanCoords; ones(1, size(scanCoords, 2))];

%figure; plot3(scannerCoords(1, :), scannerCoords(2, :), scannerCoords(3, :), 'b-');
%[ix, iy, iz] = ndgrid([0:30:256], [0:30:256], [0:4:20]);
%im2sc = inv(xform);
%sc = im2sc(1:3, :)*[ix(:) iy(:) iz(:) ones(size(ix(:)))]';
%hold on; plot3(sc(1, :), sc(2, :), sc(3, :), 'r.'); hold off
mmPerVox = [im_hdr1.pixsize_X, im_hdr1.pixsize_Y, im_hdr1.slthick];

return;
