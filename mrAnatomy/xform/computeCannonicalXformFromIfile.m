function [img2std, ifileBaseName, mmPerVox, imDim, notes, sliceSkip] = computeCannonicalXformFromIfile(anIfile)
% [img2std, ifileBaseName, mmPerVox, imDim, notes, sliceSkip] = computeCannonicalXformFromIfile(anIfile)
%
% anIfile can be any ifile now, or even just the directory containing I-files.
% This function will find the first and last slices of the volume. The headers of
% these slices are used to compute the xform. Note that we also return the number
% of image dimensions in imDim, which includes the number of slices (imDim(3)).
% This is computed based on the number of ifiles rather than read from the
% image header. We do this because the nslices field in the header is 
% wrong for some sequences that get post-processed (eg. DTI).
%
% Returns an affine xform that should orient the volume to a standard axial
% orientation with left-right along the x-axis, anterior-posterior along
% the y-axis, superior-inferior along the z-axis, and the leftmost,
% anterior-most, superior-most point at 0,0,0 (which, for Analyze/NIFTI, is
% the lower left-hand corner of the last slice). 
%
% also returns 'notes', a string of some important values pulled from the
% header (eg. patient name, some scan params, etc.)
%
% Note that the affine matrix assumes a PRE-* format and that the n 
% coordinates to be transformed are in a 4xn array. Eg:
%   imgCoords = [0 0 0 1; 0 1 0 1; 1 0 0 1]' 
%   stdCoords = img2std*imgCoords
%
% The reorientation involves only cannonical rotations and mirror flips. 
% Also, note that the reorientation depends on info in the GE I-file header- 
% if this info is wrong, the reorientation will be wrong.
%
% REQUIRES:
%   * GE2SPM (functions for reading GE header files)
%  - OR -
%   * matlab dicom tools (part of image processing toolbox >= v6.5)
%
% SEE ALSO: makeAnalyzeFromRaw, makeAnalyzeFromIfiles
%
% HISTORY:
%   2003.06.19 RFD (bob@white.stanford.edu): wrote it based on
%   makeAnalyzeFromRaw.
%
%   2003.12.01 RFD (bob@white.stanford.edu) Rewrote the algorithm to use
%   the slice-normal instead of loading the last slice's header. This makes
%   the code more elegant (gets everything from one slice) and it also
%   gives a slightly different answer in some cases. In fact, I think the
%   answer is more correct than the old method (but I can't say why it is
%   different). 
%
%   2003.12.02 RFD. Apparently, the slice-normal method didn't work for
%   some scans (depended on slice-order). I think I've fixed it now, by
%   figuring out the slice order and flipping the normal, if
%   needed.
%
%   2004.01.24 Junjie: I canNOT get everything from one slice, as the series'
%   start and end are not described in new DICOM format, i.e., se_hdr.end_loc
%   not available. Hence, I load the last slice, but still use slice-normal 
%   method. A warning is made when last slice's coordinates calculated from 
%   slice normal are different from coordinates read from last
%   slice's header.
%
%   2004.01.25 Junjie: Call getIfileNames.m to let the sorting/reading of
%   I-files accomodate DICOM (I.***.dcm) format. This code now actually
%   discards the exact file name of input anIfile and uses only its
%   dir info, and automatically detect first and last slice
%   numbers.
%
%   2004.06.03 RFD: mmPerVox now takes into account non-contiguous
%   slices (eg. slice spacing != 0)
%
%   2004.06.03 RFD: mmPerVox no longer includes slice spacing. This
%   really has to be returned as a second argument if you want to
%   deal with non-contiguous slices properly.

verbose = 1;

%%%Comment out old get Ifile names:
% if ~exist('anIfile','var') | isempty(anIfile)
%    [f, p] = uigetfile({'*.dcm','DICOM I-files (*.dcm)';'*.001','I-files (*.001)';'*.*','All files'}, 'Select one of the I-files...');
%    anIfile = fullfile(p, f);
% end
% 
% [p,f,ext] = fileparts(anIfile);
% ifileBaseName = [fullfile(p,f)];
% firstSliceNum = str2num(ext(2:end));
% 
% d = dir([ifileBaseName,'*']);
% % for DTI data, we can't rely on the header to tell us the number of slices
% % so we just count the image files and grab them all.
% nslices = length(d);
% 
% firstSlice = sprintf('%s.%0.3d', ifileBaseName, firstSliceNum);
% %lastSlice = sprintf('%s.%0.3d', ifileBaseName, firstSliceNum+nslices-1);

% To accomodate the new .dcm format, we use the new function getIfileNames.m
% to find all appropriate Ifiles in this directory.
allIfileNames = getIfileNames(anIfile);
nSlices = length(allIfileNames);
firstSlice = allIfileNames{1};
lastSlice = allIfileNames{end};

% [su_hdr,ex_hdr,se_hdr,im_hdr] = GE_readHeader(firstSlice);
[su_hdr,ex_hdr,se_hdr,im_hdr] = readIfileHeader(firstSlice); % use the more general version
% extract info from first slice.
%mmPerVox = [im_hdr.pixsize_X, im_hdr.pixsize_Y, im_hdr.slthick+im_hdr.scanspacing];
sliceSkip = im_hdr.scanspacing;
mmPerVox = [im_hdr.pixsize_X, im_hdr.pixsize_Y, im_hdr.slthick+sliceSkip];
imDim = [im_hdr.imatrix_X, im_hdr.imatrix_Y, nSlices];
% Save some key header info in a string
notes = sprintf('%s; ts=%d; %s; TR=%0.0f TI=%0.0f TE=%0.1f fp=%d NEX=%0.2f', ...
    char(ex_hdr.patname'), ex_hdr.ex_datetime, char(im_hdr.psd_iname'), im_hdr.tr/1000, ...
    im_hdr.ti/1000, im_hdr.te/1000, im_hdr.mr_flip, im_hdr.nex)

% to locate the volume in physical space, we need GE coords from another slice
[su_hdr,ex_hdr,se_hdr,im_hdr2] = readIfileHeader(lastSlice);

% We now compute our own normVec:
normVec = [im_hdr2.tlhc_R; im_hdr2.tlhc_A; im_hdr2.tlhc_S]-[im_hdr.tlhc_R; im_hdr.tlhc_A; im_hdr.tlhc_S];
normVec = normVec'./norm(normVec);
% normVec = [im_hdr.norm_R, im_hdr.norm_A, im_hdr.norm_S];

lastSliceOffset = normVec*im_hdr.slthick*(nSlices-1); % old code didn't -1, important.

%
% Find the Affine transform to reorient the volume.
%
trcRas1 = double([im_hdr.trhc_R, im_hdr.trhc_A, im_hdr.trhc_S]);
brcRas1 = double([im_hdr.brhc_R, im_hdr.brhc_A, im_hdr.brhc_S]);
tlcRas1 = double([im_hdr.tlhc_R, im_hdr.tlhc_A, im_hdr.tlhc_S]);
trcRas2 = trcRas1 + lastSliceOffset;
brcRas2 = brcRas1 + lastSliceOffset;
tlcRas2 = tlcRas1 + lastSliceOffset;

% Now compare with the coordinates in header info. We accept error within 1/1000 mm.
% comp_error = max(max(abs( [trcRas2 - double([im_hdr2.trhc_R, im_hdr2.trhc_A, im_hdr2.trhc_S]); ...
%     brcRas2 - double([im_hdr2.brhc_R, im_hdr2.brhc_A, im_hdr2.brhc_S]); ...
%     tlcRas2 - double([im_hdr2.tlhc_R, im_hdr2.tlhc_A, im_hdr2.tlhc_S])])));
% if comp_error > 0.001
%     warning('Mistake! Norm Vector does not overlap with first->last slice vector');
% end

% To guarantee that we can find any reference point, we also need to 
% specify the bottom left corner (blc), which is simple to compute via 
% vector addition (making trc the origin):
blcRas1 = trcRas1 + (tlcRas1-trcRas1) + (brcRas1-trcRas1);
blcRas2 = trcRas2 + (tlcRas2-trcRas2) + (brcRas2-trcRas2);

volRas = [tlcRas1; blcRas1; trcRas1; brcRas1; tlcRas2; blcRas2; trcRas2; brcRas2];
% We need to remember the xyz axis mappings for the GE 'tlc', 'brc', etc. convention
volXyz = [0,0,0; 1,0,0; 0,1,0; 1,1,0; 0,0,1; 1,0,1; 0,1,1; 1,1,1];
%volXyz.*repmat([im_hdr.dim_X, im_hdr.dim_Y, nSlices],size(volXyz,1),1)

% Now we need to find the correct rotation & slice reordering to bring it into 
% our standard space. We do this by finding the most right, most anterior, and 
% most superior point (ras), the most left, most anterior, and most superior 
% point (las), etc. for the current volume orientation. Note that the GE 
% convention is that negative values are left, posterior and inferior. The code 
% below does this by measuring the distance from each of the 8 corners to a 
% point in space that is, eg., very far to the left, superior and anterior 
% (-1000,1000,1000). Then, we find which of the 8 corners is closest to that 
% point. For our example, that corner would be the left-most, anterior-most, 
% superior-most point (las) in the current orientation.
d = sqrt((-1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
las = find(min(d)==d); las = las(1);
d = sqrt((1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
ras = find(min(d)==d); ras = ras(1);
d = sqrt((-1000-volRas(:,1)).^2 + (-1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
lps = find(min(d)==d); lps = lps(1);
d = sqrt((-1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (-1000-volRas(:,3)).^2);
lai = find(min(d)==d); lai = lai(1);

% Now we have the current indices of the 4 anatomical reference points- 
% las, ras, lps and lai. The following will find the current x,y,z coordinates 
% of those reference points and put them into a 4x4 matrix of homogeneous 
% coordinates.
volCoords = [volXyz(las,:),1; volXyz(lps,:),1; volXyz(lai,:),1; volXyz(ras,:),1;];

% Now we define how we *want* things to be be. That is, the x,y,z location 
% that we'd like for the las, the lps, the lai and the ras (in homogeneous 
% coords). For example:
%    stdCoords = [0,0,0,1; 0,-1,0,1; 0,0,-1,1; 1,0,0,1];
% will map A-P to y axis, L-R to x-axis, and S-I to z-axis with bottom left 
% corner of slice 1 as the most left, most anterior, most inferior point.
% If you want a diferent orientation, you should only need to change this line.
stdCoords = [0,0,0,1; 0,-1,0,1; 0,0,-1,1; 1,0,0,1];

% The following will produce an affine transform matrix that tells us how 
% to transform to our standard space. To use this xform matrix, do: 
% stdCoords = img2std*imgCoords (assuming imgCoords is an 4xn array of n 
% homogeneous coordinates).
img2std = (volCoords \ stdCoords)';

% Fix the translations so that mirror-flips are achieved by -1 rotations.
% This obtuse code relies on the fact that our xform is just 0s 1s and -1s.
% For the rotation part ([1:3],[1:3]), each row should have only one
% nonzero value. If that value is -1, then that denotes a mirror flip. So,
% we set the translations for those dimensions to be imDim rather than 0.
% (Note that we sum across the columns to find the correct imDim value.)
% This way, we get a valid index rather than a negative coord.
img2std(sum(img2std([1:3],[1:3])')<0,4) = imDim(sum(img2std([1:3],[1:3]))<0)';
img2std(sum(img2std([1:3],[1:3])')>0,4) = 0;

% Note that we have constructed this transform matrix so that it will 
% only involve 90, 180 or 270 deg rotations by specifying corresponding 
% points from cannonical locations (the corners of the volume- see stdCoords 
% and volCoords).

[p f junk] = fileparts(firstSlice);
ifileBaseName = fullfile(p,f);

if(verbose)
    disp(['Processing Ifiles: ' ifileBaseName,'*...']);
    disp('Original volume orientation:');
    disp(sprintf('first slice tlc: %+04.1f %+.1f %+.1f', tlcRas1));
    disp(sprintf('first slice blc: %+.1f %+.1f %+.1f', blcRas1));
    disp(sprintf('first slice trc: %+.1f %+.1f %+.1f', trcRas1));
    disp(sprintf(' last slice tlc: %+.1f %+.1f %+.1f', tlcRas2));
    disp('Transform matrix:');
    disp(img2std);
end

return;
