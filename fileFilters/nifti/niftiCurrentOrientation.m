function [vectorString, orientationMatrix] = niftiCurrentOrientation(nii)
%
% [orientationStr, orientationMatrix] = niftiCurrentOrientation(nii)
% Computes the orientation of the nifti file passed in and returns both 
% a vector of 3 characters as well as a standard 4x4 matrix  
%
% USAGE
%  nii = readNifti(niftiFullPath);
%  niftiCurrentOrientation(nii);
%
% INPUTS
%  Nifti struct
%
% RETURNS
%  Vector string of orientation (e.g. 'ARS')
%  Xform necessary to return to ARS format
%
%
% VistaLab 2013-02-05

%Extract information on the current transform and dimension size
xform = niftiGet(nii, 'Qto_xyz');
imDim = niftiGet(nii, 'Dim');

imDim = imDim(1:3);

% Check whether any dimensions are 1 voxel. If so, we need to pad in order
%   to avoid errors arising from computing anatomical direction in that
%   dimension
imDim(imDim == 1) = 2;

%The following code was taken from mrAnatComputeCannonicalXformFromDicomXform

% Compute the scanner-space locations of the image volume corners
imgCorners = [
    1 1 1 1; 
    imDim(1) 1 1 1; 
    1 imDim(2) 1 1; 
    imDim(1) imDim(2) 1 1; 
    1 1 imDim(3) 1; 
    imDim(1) 1 imDim(3) 1; 
    1 imDim(2) imDim(3) 1; 
    imDim(1) imDim(2) imDim(3) 1;
    ];

% imDimC = imDim + .5;
% imgCorners = [
%     .5 .5 .5 1; 
%     imDimC(1) .5 .5 1; 
%     .5 imDimC(2) .5 1; 
%     imDimC(1) imDimC(2) .5 .1; 
%     .5 .5 imDimC(3) 1; 
%     imDimC(1) .5 imDimC(3) 1; 
%     .5 imDimC(2) imDimC(3) 1; 
%     imDimC(1) imDimC(2) imDimC(3) 1;
%     ];

volRas = xform*imgCorners';
volRas = volRas(1:3,:)';


% Now we need to find the correct rotation & slice reordering to bring
% volXyz into our standard space. We do this by identifying 4 corners of
% the slab: LAS (the most left, most anterior, and most superior point),
% RAS, LPS, AND LAI for the current volume orientation. Note that the NIFTI
% convention is that negative values are left, posterior and inferior. The
% code below finds the correct rotation by measuring the distance from each
% of the 8 corners to a point in space that is very far to the left,
% superior and anterior*. This gives us LAS. We then constrain the search
% for the three other corners (RAS, LPS, LAI) to the three corners are
% topologically adjacent to LAS. 
%
% *Originally, this was (-1000,1000,1000), however, to make this no longer
% arbitrary, this was changed to be 2 orders of magnitude larger than the
% largest value in VolRas. Then, we find which of the 8 corners is closest
% to that point.
extPtValue = 100 * max(max(abs(volRas)));

% function handle to compute the norm of each row of a nx3 matrix
rowNorm = @(x) sqrt(sum(x.*x, 2));

% find nearest corner to LAS
d = rowNorm(bsxfun(@minus, volRas, extPtValue*[-1 1 1]));
las = find(min(d)==d, 1);

% Find the 3 corners which are topologically adjacent to LAS. this amounts
% to the three corners of imgCoords which differ by the LAS corners in
% exactly one coordinate;
neighbors = find(sum(bsxfun(@eq, imgCorners,  imgCorners(las,:)),2) == 3);
volRas = volRas(neighbors,:);

% find nearest corner to RAS
d = rowNorm(bsxfun(@minus, volRas, extPtValue*[1 1 1]));
ras = find(min(d)==d, 1); ras = neighbors(ras);

% find nearest corner to LPS
d = rowNorm(bsxfun(@minus, volRas, extPtValue*[-1 -1 1]));
lps = find(min(d)==d,1); lps  = neighbors(lps);

% find nearest corner to LAI
d = rowNorm(bsxfun(@minus, volRas, extPtValue*[-1 1 -1]));
lai = find(min(d)==d,1); lai  = neighbors(lai);


% The same volRas image corners represented with 0,1:
volXyz = [0,0,0; 1,0,0; 0,1,0; 1,1,0; 0,0,1; 1,0,1; 0,1,1; 1,1,1];

% Now we have the indices into volRas/volXyz of the 4 anatomical 
% reference points- las, ras, lps and lai.
volCoords = [volXyz(las,:); volXyz(lps,:); volXyz(lai,:); volXyz(ras,:);];

%We now have a matrix of volCoords, where we know that the first row is
%las, the second row lps, the 3rd row lai and the last row ras.
% Taking las as our point of reference, we can change one direction at a
% time and see which points change. That is direction -- axis mapping

%Now, let's reassign the orientations to the row they represent:
las = 1;
lps = 2;
lai = 3;
ras = 4;

%To be in RAS, we are looking for the following to hold:
% RAS - LAS > 0
% LAS - LPS > 0
% LAS - LAI > 0

%% Find the direction of L-R, A-P, S-I

% Get LR dimension (1,2,or 3) and direction (-1 or 1)
tmp = volCoords(ras,:) - volCoords(las,:);
RLcol = find(tmp);
RLcol = RLcol(1); %Since an array was previously returned
RLdir = sign(tmp(RLcol)); %Get the direction of it as well

% Get AP dimension (1,2,or 3) and direction (-1 or 1)
tmp = volCoords(las,:) - volCoords(lps,:);
APcol = find(tmp);
APcol = APcol(1);
APdir = sign(tmp(APcol)); %Get the direction of it as well

% Get SI dimension (1,2,or 3) and direction (-1 or 1)
tmp = volCoords(las,:) - volCoords(lai,:);
SIcol = find(tmp);
SIcol = SIcol(1);
SIdir = sign(tmp(SIcol)); %Get the direction of it as well


%Now to figure out what string should appear at each location
if RLdir > 0, vectorString(RLcol) = 'R'; else, vectorString(RLcol) = 'L'; end
if APdir > 0, vectorString(APcol) = 'A'; else, vectorString(APcol) = 'P'; end
if SIdir > 0, vectorString(SIcol) = 'S'; else, vectorString(SIcol) = 'I'; end

orientationMatrix = niftiCreateXformFromString(vectorString);

return