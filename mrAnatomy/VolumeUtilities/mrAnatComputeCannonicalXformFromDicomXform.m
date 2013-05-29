function [img2std] = mrAnatComputeCannonicalXformFromDicomXform(xform, imDim)
% Create a transform from scanner space to a standard space
%
%   [img2std] = ...
%    mrAnatComputeCannonicalXformFromDicomXform(scannerToImXform, imDim)
%
% Given a DICOM-standard scanner-to-image space transform matrix (e,g. the
% NIFTI qto_xyz xform), this function computes and returns a 4x4 xform that
% will reorient the volume to a standard orientation described below. (Use
% applyCannonicalXform to actually transform the data).
%
% The img2std xform will reorient axes so that 
%   right-left is along the x-axis  
%     (is this column, really, or first dimenion, which is row)
%   anterior-posterior is along the y-axis (2nd dimension?)
%   superior-inferior is along the z-axis  (3rd dimension?)
% and the leftmost, anterior-most, superior-most point is at 0,0,0 (which,
% for Analyze/NIFTI, is the lower left-hand corner of the last slice).  
%
% ** Please check whether RAS has the left most at 0 or the rightmost at 0. BW **
%
% Note that the img2std matrix assumes a PRE-* format and that the n 
% coordinates to be transformed are in a 4xn array. Eg:
%   imgCoords = [0 0 0 1; 0 1 0 1; 1 0 0 1]' 
%   stdCoords = img2std*imgCoords
%
% The reorientation involves only cannonical rotations and mirror flips.
% Also, note that the reorientation depends on the input xform being a
% proper DICOM xform that converts coords from image space to the DICOM
% standard physical space. Obviously, if this info is wrong, the
% reorientation will be wrong.
%
% Web resources:
%    mrvBrowseSVN('mrAnatComputeCannonicalXformFromDicomXform');
%
% SEE ALSO: 
%   applyCannonicalXform
%   computeCannonicalXformFromIfile
%
% HISTORY:
%   2007.04.19 RFD (bob@white.stanford.edu): wrote it based on
%   computeCannonicalXformFromIfile.
%   
% (c) Stanford VISTALAB

% Compute the scanner-space locations of the image volume corners
imgCorners = [1 1 1 1; imDim(1) 1 1 1; 1 imDim(2) 1 1; imDim(1) imDim(2) 1 1; ...
    1 1 imDim(3) 1; imDim(1) 1 imDim(3) 1; 1 imDim(2) imDim(3) 1; imDim(1) imDim(2) imDim(3) 1];
volRas = xform*imgCorners';
volRas = volRas(1:3,:)';
% The same volRas image corners represented with 0,1:
volXyz = [0,0,0; 1,0,0; 0,1,0; 1,1,0; 0,0,1; 1,0,1; 0,1,1; 1,1,1];


% Now we need to find the correct rotation & slice reordering to bring 
% volXyz into our standard space. We do this by finding the most right, 
% most anterior, and most superior point (ras), the most left, most 
% anterior, and most superior point (las), etc. for the current volume 
% orientation. Note that the NIFTI convention is that negative values 
% are left, posterior and inferior. The code below finds the correct 
% rotation by measuring the distance from each of the 8 corners to a 
% point in space that is very far to the left, superior and anterior 
% (-farpoint,farpoint,farpoint). Then, we find which of the 8 corners is closest to
% that point. 

% pick a big number relative to the volume coordinates
farpoint = 10000;

% function handle to compute the distance of each row of a nx3 matrix
rowNorm = @(x) sqrt(sum(x.*x, 2));

% find nearest corner to LAS
d = rowNorm(bsxfun(@minus, volRas, farpoint*[-1 1 1]));
las = find(min(d)==d); las = las(1);

% find nearest corner to RAS
d = rowNorm(bsxfun(@minus, volRas, farpoint*[1 1 1]));
d(las) = Inf;
ras = find(min(d)==d); ras = ras(1);

% find nearest corner to LPS
d = rowNorm(bsxfun(@minus, volRas, farpoint*[-1 -1 1]));
d([las ras]) = Inf;
lps = find(min(d)==d); lps = lps(1);

d = rowNorm(bsxfun(@minus, volRas, farpoint*[1 -1 1]));
d([las ras lps]) = Inf;
rps = find(min(d)==d); rps = rps(1);

% find nearest corner to LAI
d = rowNorm(bsxfun(@minus, volRas, farpoint*[-1 1 -1]));
d([las ras lps rps]) = Inf;
lai = find(min(d)==d); lai = lai(1);

d = rowNorm(bsxfun(@minus, volRas, farpoint*[1 1 -1]));
d([las ras lps rps lai]) = Inf;
rai = find(min(d)==d); rai = rai(1);

d = rowNorm(bsxfun(@minus, volRas, farpoint*[-1 -1 -1]));
d([las ras lps rps lai rai]) = Inf;
lpi = find(min(d)==d); lpi = lpi(1);

% The last point, rpi, is the only one left:
d = rowNorm(bsxfun(@minus, volRas, farpoint*[1 -1 -1]));
d([las ras lps rps lai rai lpi]) = Inf;
rpi = find(min(d)==d); rpi = rpi(1);


% Now we have the indices into volRas/volXyz of the 4 anatomical 
% reference points- las, ras, lps and lai. Put them into a 4x4 matrix 
% of homogeneous coordinates.
volCoords = [volXyz(las,:),1; volXyz(ras,:),1; volXyz(lps,:),1; volXyz(rps,:),1; volXyz(lai,:),1; volXyz(rai,:),1; volXyz(lpi,:),1; volXyz(rpi,:),1;];

% Now we define how we *want* things to be be. That is, the x,y,z location 
% that we'd like for the las, the lps, the lai, etc. (in homogeneous 
% coords). The coords here will map A-P to y axis, L-R to x-axis, and S-I 
% to z-axis with bottom left corner of slice 1 as the most left, most 
% anterior, most inferior point. If you want a diferent orientation, you 
% should only need to change this line.
% NIFTI convention is that negative values are left, posterior and inferior.
stdCoords = [-1,1,1,2; 1,1,1,2; -1,-1,1,2; 1,-1,1,2; -1,1,-1,2; 1,1,-1,2; -1,-1,-1,2; 1,-1,-1,2] / 2;

% The following will produce an affine transform matrix that tells us how 
% to transform to our standard space. To use this xform matrix, do: 
% stdCoords = img2std*imgCoords (assuming imgCoords is an 4xn array of n 
% homogeneous coordinates).
img2std = (volCoords \ stdCoords)';

% In cases where the original orientation is exactly in the middle of where
% we want to go, img2std will be indterminate (i.e., there are multiple,
% equally valid, solutions). Here's an ugly hack to just pick one solution
% and go with it.
[m,maxind1] = max(abs(img2std(1:3,1)));
% retain the sign of the winner
new_val = sign(img2std(maxind1,1));
% zero-out all the losers
img2std(1:3,1) = 0;
img2std(maxind1,2:3) = 0;
% insert the new value back in
img2std(maxind1,1) = new_val;
% repeat for the next column
[m,maxind2] = max(abs(img2std(1:3,2)));
new_val = sign(img2std(maxind2,2));
img2std(1:3,2) = 0;
img2std(maxind2,3) = 0;
img2std(maxind2,2) = new_val;
% and the last one is easy
maxind3 = setdiff([1 2 3], [maxind1 maxind2]);
if img2std(maxind3,3)==0
    % this would be a really degenerate case. But we have to do something
    % for any xform they throw at us.
    img2std(maxind3,3) = 1;
else
    img2std(maxind3,3) = sign(img2std(maxind3,3));
end

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

return;
