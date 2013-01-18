function destination = BV_CombineWithMask(sourceFile, destinationFile, maskFile, outFile, normalizeImages)
%
%   destination = BV_CombineWithMask(sourceFile, destinationFile, maskFile, outFile)
%
% Combines Analyze images using a mask
%
% Like this:
%    destination(mask) = source(mask);
%
% EXAMPLE: 
%       BV_CombineWithMask(homog_brain, orig, brain_mask);
%
% $Author: bob $
% $Date: 2003/12/20 00:01:50 $

if (~exist('normalizeImages','var'))
    normalizeImages=0;
end
if ~exist('outFile','var')
    outFile = [destinationFile,'_Combined']
end
    
% Load in the images:
[source,mmPerVox]      = loadAnalyze(sourceFile,'',1);
[destination,mmPerVox] = loadAnalyze(destinationFile,'',1);

% Assume that mask is 0s and 1s
mask = loadAnalyze(maskFile,'',1);
mask = mask~=0;

% Do some normalization if required
if (normalizeImages);
    disp('Normalizing...');
    source = double(source);
    source = source-min(source(:));
    source = source/max(source(:))*65000;
    source = uint16(source);
    destination = double(destination);
    destination = destination-min(destination(:));
    destination = destination/max(destination(:))*65000;
    destination = uint16(destination);
end

% Take the locations in the Source that are in the mask positions
% and copy them into the Destination file.
destination(mask) = source(mask);

if nargout == 0
    saveAnalyze(double(destination),outFile, mmPerVox);
    fprintf('Saving combined file:  %s\n',outFile);
end

return;



