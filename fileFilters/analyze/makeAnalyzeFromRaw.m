function makeAnalyzeFromRaw(img, ifile1, ifile2, nSlices, outFileName, options)
% makeAnalyzeFromRaw(img, ifile1, ifile2, [nSlices], [outFileName], [options])
%
% img is the 3d array of image data.
%
% ifile1 and ifile2 should point to the first and last slice of the volume.
% The headers of these are used to properly format the analyze data.
%
% If nSlices is empty or omitted, it will be extracted from the header of
% ifile1. (For DICOM format, count files in ifile path).
%
% outFileName should not include '.hdr' or '.img'- just the base name.
% It defaults to a reasonable file name in the current working directory.
%
% options is a cell array specifying various little options. Currently 
% supported options:
%   'verbose' : displays various bits of information and progress (default).
%   'silent'  : opposite of verbose.
% 
% The data in the resulting Analyze file will be oriented according to 
% the default Analyze convention- 'transverse unflipped' (orient code '0' in 
% the .hdr file). That is, the image will be reoriented so that left-right is 
% along the x-axis, anterior-posterior is along the y-axis, superior-inferior 
% is along the z-axis, and the leftmost, anterior-most, superior-most point is 
% at 0,0,0 (which, for Analyze, is the lower left-hand corner of the last slice). 
%
% To help you find the 0,0,0 point, a 4-pixel rectange is drawn there with a pixel
% value equal to the maximum image intensity.
%
% The reorientation involves only cannonical rotations and mirror flips- no
% interpolation is performed. Also, note that the reorientation depends on info
% in the GE I-file header- if this info is wrong, the reorientation will be wrong.
%
% REQUIRES:
%   * SPM99 utilities
%   * Stanford Anatomy and filter functions
%
% SEE ALSO: loadAnalyze, saveAnalyze, analyze2mrGray, mrGray2Analyze
%
% HISTORY:
%   2002.05.31 RFD (bob@white.stanford.edu): wrote it.
%   2002.06.5 RFD: got it to actually work reliably.
%   2002.06.14 RFD: cleaned up the code and added more comments.
%   2004.01.24 Junjie: use readIfileHeader.m instead of GE_readHeader to
%   accomodate DICOM format ifiles. nSlices read from getIfileNames.m. Other
%   parts unchanged, however, please see computeCannonicalXformFromIfile.m for
%   discussion about slice-normal method.

if(~exist('ifile1','var') | isempty(ifile1) | ~exist('ifile2','var') | isempty(ifile2) ...
        | ~exist('img','var') | isempty(img))
    help(mfilename);
    return;
end
if(~exist('outFileName','var') | isempty(outFileName))
    [p,f] = fileparts(ifile1);
    outFileName = fullfile(pwd, f);
end
if(~exist('options','var'))
    options = {};
end
opt = parseOptions(options);

[su_hdr,ex_hdr,se_hdr,im_hdr] = readIfileHeader(ifile1);
if(~exist('nSlices','var') | isempty(nSlices))
    % Now, the DICOM format of i-files does not provide numimages info, so you
    % need to count all i-files in the folder.
    nSlices = length(getIfileNames(ifile1));
end
mmPerVox = [im_hdr.pixsize_X, im_hdr.pixsize_Y, im_hdr.slthick];
imDim = [im_hdr.imatrix_X, im_hdr.imatrix_Y, nSlices];
% to locate the volume in physical space, we need GE coords from another slice
[su_hdr,ex_hdr,se_hdr,im_hdr2] = readIfileHeader(ifile2);

% Now we find the Affine transform to make the voxels isotropic and orient the
% volume to the talairach standard (upper left pixel is right, anterior, superior).
trcRas1 = [im_hdr.trhc_R, im_hdr.trhc_A, im_hdr.trhc_S];
brcRas1 = [im_hdr.brhc_R, im_hdr.brhc_A, im_hdr.brhc_S];
tlcRas1 = [im_hdr.tlhc_R, im_hdr.tlhc_A, im_hdr.tlhc_S];
trcRas2 = [im_hdr2.trhc_R, im_hdr2.trhc_A, im_hdr2.trhc_S];
brcRas2 = [im_hdr2.brhc_R, im_hdr2.brhc_A, im_hdr2.brhc_S];
tlcRas2 = [im_hdr2.tlhc_R, im_hdr2.tlhc_A, im_hdr2.tlhc_S];
% To guarantee that we can find any reference point, we also need to specify the 
% bottom left corner (blc), which is simple to compute via vector addition (making
% trc the origin):
blcRas1 = trcRas1 + (tlcRas1-trcRas1) + (brcRas1-trcRas1);
blcRas2 = trcRas2 + (tlcRas2-trcRas2) + (brcRas2-trcRas2);

volRas = [tlcRas1; blcRas1; trcRas1; brcRas1; tlcRas2; blcRas2; trcRas2; brcRas2];
% We need to remember the xyz axis mappings for the GE 'tlc', 'brc', etc. convention
volXyz = [0,0,0; 1,0,0; 0,1,0; 1,1,0; 0,0,1; 1,0,1; 0,1,1; 1,1,1];
%volXyz.*repmat([im_hdr.dim_X, im_hdr.dim_Y, nSlices],size(volXyz,1),1)

% Now we need to find the correct rotation & slice reordering to bring it into our standard space.
% We do this by finding the most right, most anterior, and most superior point (ras), the
% most left, most anterior, and most superior point (las), etc. for the current volume orientation.
% Note that the GE convention is that negative values are left, posterior and inferior.
% The code below does this by measuring the distance from each of the 8 corners to a point in space
% that is, eg., very far to the left, superior and anterior (-1000,1000,1000). Then, we find which
% of the 8 corners is closest to that point. For our example, that corner would be the left-most, 
% anterior-most, superior-most point (las) in the current orientation.
d = sqrt((-1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
las = find(min(d)==d); las = las(1);
d = sqrt((1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
ras = find(min(d)==d); ras = ras(1);
d = sqrt((-1000-volRas(:,1)).^2 + (-1000-volRas(:,2)).^2 + (1000-volRas(:,3)).^2);
lps = find(min(d)==d); lps = lps(1);
d = sqrt((-1000-volRas(:,1)).^2 + (1000-volRas(:,2)).^2 + (-1000-volRas(:,3)).^2);
lai = find(min(d)==d); lai = lai(1);

% Now we have the current indices of the 4 anatomical reference points- las, ras, lps and lai. 
% The following will find the current x,y,z coordinates of those reference points and put them
% into a 4x4 matrix of homogeneous coordinates.
volCoords = [volXyz(las,:),1; volXyz(lps,:),1; volXyz(lai,:),1; volXyz(ras,:),1;];

% Now we define how we *want* things to be be. That is, the x,y,z location that we'd like for
% the las, the lps, the lai and the ras (in homogeneous coords).
% For example:
%    stdCoords = [0,0,0,1; 0,-1,0,1; 0,0,-1,1; 1,0,0,1];
% will map A-P to y axis, L-R to x-axis, and S-I to z-axis with bottom left corner of slice 1 
% as the most left, most anterior, most inferior point.
% If you want a diferent cannonical view, you should only need to change this line.
stdCoords = [0,0,0,1; 0,-1,0,1; 0,0,-1,1; 1,0,0,1];

% The following will produce an affine transform matrix that tells us how to transform
% to our standard space.
std2vol = stdCoords \ volCoords;
% Extract rotation & scale matrix. We have set things up so that the scales should be 1.
std2volRot = round(std2vol(1:3,1:3));
% to use this xform matrix, do: volCoords = [stdCoords,1]*std2vol
% Note that we have constructed this transform matrix so that it will only involve cannonical
% rotations. We did this by specifying corresponding points from cannonical locations (the corners
% of the volume- see stdCoords and volCoords).
if(opt.verbose)
    disp('Original volume orientation:');
    disp(sprintf('first slice tlc: %+04.1f %+.1f %+.1f', tlcRas1));
    disp(sprintf('first slice blc: %+.1f %+.1f %+.1f', blcRas1));
    disp(sprintf('first slice trc: %+.1f %+.1f %+.1f', trcRas1));
    disp(sprintf(' last slice tlc: %+.1f %+.1f %+.1f', tlcRas2));
    disp('Transform matrix:');
    disp(std2vol);
end

% Now, load the image data and apply the transform.
%img = makeCubeIfiles(ifileDir, imDim([1,2]), [1:nSlices]);

% We use shortcuts to apply the transform. Since all rotations are cannonical, we can achieve
% them efficiently by swapping dimensions with 'permute'.
% The dimension permutation logic- we want to know which of the current dimensions should be x, 
% which should be y, and which should be z:
xdim = find(abs(std2volRot(1,:))==1);
ydim = find(abs(std2volRot(2,:))==1);
zdim = find(abs(std2volRot(3,:))==1);
mmPerVoxNew = [mmPerVox(xdim), mmPerVox(ydim), mmPerVox(zdim)];
tmp=['X','Y','Z']; 
if(opt.verbose) disp(['permuting dimensions from XYZ to ',[tmp(xdim), tmp(ydim), tmp(zdim)],'...']); end
img = permute(img, [xdim, ydim, zdim]);

% Now do any necessary mirror flips (indicated by negative rotation matrix values).
if(std2volRot(1,xdim)<0)
    % flip each slice ud (ie. flip along matlab's first dimension, which is our x-axis)
    if(opt.verbose) disp('flip along (new) x-axis...'); end
    for(jj=1:size(img,3))
        img(:,:,jj) = flipud(squeeze(img(:,:,jj)));
    end
end
if(std2volRot(2,ydim)<0)
    % flip each slice lr(ie. flip along matlab's second dimension, which is our y-axis)
    if(opt.verbose) disp('flip along (new) y-axis...'); end
    for(jj=1:size(img,3))
        img(:,:,jj) = fliplr(squeeze(img(:,:,jj)));
    end
end   
if(std2volRot(3,zdim)<0)
    % reorder slices
    if(opt.verbose) disp('flip along (new) z-axis...'); end
    for(jj=1:size(img,1))
        img(jj,:,:) = fliplr(squeeze(img(jj,:,:)));
    end
end

% insert a marker at 1,end,end (should be left, anterior, superior 
% given stdCoords of [0,0,0; 0,-1,0; 0,0,-1; -1,0,0])
img(1,end,end) = max(img(:));
img(2,end,end) = img(end,1,end);
img(1,end-1,end) = img(end,1,end);
img(2,end-1,end) = img(end,1,end);

if(opt.verbose) disp(['Saving ',outFileName,'.hdr and ',outFileName,'.img ...']); end
notes = sprintf('%s; ts=%d; %s; TR=%0.0f TI=%0.0f TE=%0.1f fp=%d NEX=%0.2f', ...
    char(ex_hdr.patname'), ex_hdr.ex_datetime, char(im_hdr.psd_iname'), im_hdr.tr/1000, ...
    im_hdr.ti/1000, im_hdr.te/1000, im_hdr.mr_flip, im_hdr.nex)
hdr = saveAnalyze(img, outFileName, mmPerVoxNew, notes);

return;


function opt = parseOptions(optionsCell)
if(~iscell(optionsCell)) 
    optionsCell = {optionsCell};
end
optionsCell = lower(optionsCell);
if(strmatch('silent', optionsCell))
    opt.verbose = 0;
else
    opt.verbose = 1;
end
return;