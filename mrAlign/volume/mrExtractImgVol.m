function img = mrExtractImgVol(volume,iSize,numSlices,samp, ...
                                 dataRange,badVal)
%
%  img = mrExtractImgVol(volume,iSize,numSlices,samp,dataRange,badVal)
%
%AUTHOR:  Engel
%DATE:    November, 1994
%PURPOSE:
%  Extracts and interpolates the values from a volume of data.
% The locations to be returned are listed in the parameter samp.
%
% The input volume is formatted so that each row is an image 
%
% The sampling grid is a matrix whose columns are x,y,and z.
% For the image to be displayable using myShowImage, the sampling
% matrix should run down columns fastest, rows slowest.
%
% volume:     a volume of data represented as a vector
% iSize:      the row and col size of individual images in the volume
% numSlices:  the number of image slices in the volume
% samp:       the sample locations we wish to extract from the volume.
%
% OPTIONAL ARGUMENTS:
% dataRange:  the starting and ending Z-coordinates for the 
%	      volume of data.  It is optional. If no dataRange is given
%	      the Z range is assumed to be 1:numSlices. This allows subsets
%             of the full volume to be passed in.
%
% badVal:  specifies the value that should be returned
%	   for values outside the data set.
%
% global interpflag:  the value of this global specifies whether or not
% 	              to interpolate the volume data.
%
% RETURNED:
%   img:     an image is returned, selected from the volume data
%	     according to the samp values.
%

% BW 10/19/95

global interpflag

% Check arguments
%
if (nargin < 6) 	% No badVal
 badVal = 1;
end
if (nargin >= 5) 	% There is a dataRange argument
 samp(:,3) = samp(:,3) - dataRange(1) + 1;
end
if (nargin < 4)
 error('mrExtractImgVol:  Requires 4 arguments')
end

% If the global interpolation flag is set, then interpolate the data.
% to make sure there are values at the sample values.
%
if (interpflag)

% myCinterp3 uses trilinear interpolation to create a value
% at each samp location.  It refuses to extrapolate, so if
% a sample point is outside the volume size, badVal is returned
% 
 img = myCinterp3(volume,iSize,numSlices,samp,badVal)';

else

% Check the samp range to make sure we are not out of bounds.
% Points that are out of bounds will be assigned badVal
%
 bad = (samp(:,1) > iSize(2)) | (samp(:,2) > iSize(1)) ...
 | (samp(:,3) > (numSlices+.5)) | (samp(:,1) < .5)  ...
 | (samp(:,2) < 1) | (samp(:,3) < 1);

% Convert the 3d coordinates to the volume coord.
%
  volcoords = mrVcoord(round(samp),iSize);
% volcoords = mr3d21d(samp,iSize,[1,numSlices]);

%Take care of out of bounds points
%
 bad = bad | (volcoords < 1 )| (volcoords > length(volume));

%Extract data.  Notice that badVal is used here, too.
%
 img = zeros(size(volcoords));
 img(~bad) = volume(volcoords(~bad));
 img(bad) = badVal*ones(1,sum(bad));

% Replaced this line.  Does this make trouble for someone? -- BW
%
% img(isnan(img)) = badVal*ones(1,sum(isnan(img)));
end

