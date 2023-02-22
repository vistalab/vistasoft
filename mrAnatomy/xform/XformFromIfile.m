function [Xform,mmPerVox] = XformFromIfile(ifileDir,option)
% Determine the 4x4 transform (affine) that maps GE scanner coordinates
% to 3D physical coordinates (acpc space? mm? let's define axes). 
%
%   [Xform,mmPerVox] = XformFromIfile(ifileDir,option)
%
%   INPUTS:
%       ifileDir:   must include the filename prefix- eg. 'spgr1/I' for I-files that look 
%                   like 'I.001', I.002, ...'.
%       option:     must be equal to 'volume' if you are dealing with vAnatomy 
%                   Ifiles or 'inplane' if you are dealing with inplane Ifiles
%
%   HISTORY:    7.22.2002 - Sunjay Lad (slad@stanford.edu) - wrote it
%   2003.11.25 RFD (bob@white.stanford.edu) Rewrote the algorithm to use
%   the slice-normal instead of loading the last slice's header. This makes
%   the code more elegant (gets everything from one slice) and it also
%   gives a slightly different answer in some cases. In fact, I think the
%   answer is more correct than the old method (but I can't say why it is
%   different). 
%
%   2004.06.04 RFD  The normVec method doesn't work so well for the new dicom data, since
%              dicom doesn't specify the normVec. So, I've reverted to
%              using the last slice. I also adjusted mmPerVox to accomodate
%              non-contiguous slices.

if(~exist('ifileDir','var') | isempty(ifileDir)),  help(mfilename); return; end

% To accomodate the new .dcm format, we use the new function getIfileNames.m
% to find all appropriate Ifiles in this directory.
allIfileNames = getIfileNames(ifileDir);
nSlices = length(allIfileNames);
firstSlice = allIfileNames{1};
lastSlice = allIfileNames{end};

% Extracts the header info from the first Ifile
[su_hdr1,ex_hdr1,se_hdr1,im_hdr1] = readIfileHeader(firstSlice);
[su_hdr2,ex_hdr2,se_hdr2,im_hdr2] = readIfileHeader(lastSlice);

nSlices = length(allIfileNames);
mmPerVox = [im_hdr1.pixsize_X, im_hdr1.pixsize_Y, im_hdr1.slthick+im_hdr1.scanspacing];

% We now compute our own normVec:
normVec = [im_hdr2.tlhc_R; im_hdr2.tlhc_A; im_hdr2.tlhc_S]-[im_hdr1.tlhc_R; im_hdr1.tlhc_A; im_hdr1.tlhc_S];
normVec = normVec./norm(normVec);
%normVec = [im_hdr1.norm_R; im_hdr1.norm_A; im_hdr1.norm_S];
% the slice normal is always pointing in a positive direction. So, we have
% to figure out which way the slices were pulled off and adjust the normVec
% accordingly.
% if(se_hdr1.end_loc < se_hdr1.start_loc)
%     normVec = -normVec;
% end
%lastSliceOffset = normVec*im_hdr1.slthick*nSlices;
% the GE positions refer to the pixel centers, but we want to find the
% points that define the outer surface of the image volume, so we need to
% offset by half a voxel.
%firstSliceOffset = normVec.*mmPerVox'./2;
% For some reason I don't understand, this offset (1.5 slices) seems to
% work much better. 
%firstSliceOffset = normVec.*im_hdr1.slthick.*1.5;
% I've decied to try to avoid things that I don't understand. The slice
% offset should be exactly half a slice, so we will use that.
sliceOffset = normVec.*im_hdr1.slthick.*0.5;

% GE scanner coords for top left corner of first slice
tlc1 = [im_hdr1.tlhc_R, im_hdr1.tlhc_A, im_hdr1.tlhc_S]'-sliceOffset;
% GE scanner coords for top right corner of first slice
trc1 = [im_hdr1.trhc_R, im_hdr1.trhc_A, im_hdr1.trhc_S]'-sliceOffset;
% GE scanner coords for bottom right corner of first slice
brc1 = [im_hdr1.brhc_R, im_hdr1.brhc_A, im_hdr1.brhc_S]'-sliceOffset;
% GE scanner coords for top left corner of last slice
tlc2 = [im_hdr2.tlhc_R, im_hdr2.tlhc_A, im_hdr2.tlhc_S]'+sliceOffset;
%tlc2 = tlc1 + lastSliceOffset;
% GE scanner coords for bottom right corner of last slice
brc2 = [im_hdr2.brhc_R, im_hdr2.brhc_A, im_hdr2.brhc_S]'+sliceOffset;
%brc2 = brc1 + lastSliceOffset;

% GE scanner coords for all 4 points (homogeneous coords; 4x4 matrix)
scannerCoords = [[tlc1,trc1,tlc2,brc2]; ones(1,4)];

if (strcmp(option,'volume'))
    % Pixel coords for top left corner of first slice
    pixel_tl1 = [0, 0, 0]';
    % Pixel coords for top right corner of first slice
    pixel_tr1 = [im_hdr1.imatrix_X, 0, 0]';
    % Pixel coords for top left corner of last slice
    pixel_tl2 = [0, 0, nSlices]';
    % Pixel coords for bottom right corner of last slice
    pixel_br2 = [im_hdr1.imatrix_X, im_hdr1.imatrix_Y, nSlices]';
    
    % might be necessary if there were spacing between slices
    % pixel_tl2 = [0, 0, (nSlices - 1)*(1 + (im_hdr1.scanspacing/im_hdr1.slthick))]'
end

if (strcmp(option,'inplane'))
    global mrSESSION
    % Accounts for cropping of inplanes - applies "cropping" here before computing 
    % Xform (using negative coords) 
    crop = mrSESSION.inplanes.crop;
    pixel_tl1 = [-crop(1,1), -crop(1,2), 0.5]';
    pixel_tr1 = [im_hdr1.imatrix_X - crop(1,1), -crop(1,2), 0.5]';
    pixel_tl2 = [-crop(1,1), -crop(1,2), nSlices-0.5]';
    pixel_br2 = [im_hdr1.imatrix_X - crop(1,1), im_hdr1.imatrix_Y - crop(1,2), nSlices-0.5]';
end

% Pixel coords for all 4 slices (4x4 matrix)
pixelCoords = [[pixel_tl1,pixel_tr1,pixel_tl2,pixel_br2]; ones(1,4)];

% 4x4 transform from GE scanner coords -> pixel coords
Xform = pixelCoords / scannerCoords;

% currently we get volSize from the vAnatomy.dat header ... this is another place where 
% this data could be acquired if we ever do away with vAnatomy.dat
%
% volSize = [im_hdr1.imatrix_X, im_hdr1.imatrix_Y, nSlices];

return;