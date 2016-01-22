function [ipFuncCoords, inds] = ip2functionalCoords(inplane, ipAnatCoords, ...
    scan, preserveCoords, preserveExactValues)
% Convert coordinates from inplane anatomy to inplane functional. 
%
%   [ipFuncCoords, inds] = ip2functionalCoords(inplane, ipAnatCoords, ...
%       [scan=1], [preserveCoords=false, [preserveExactValues=false])
%
% It is necessary to convert from anatomical space to functional space
% because the resolution of the inplane anatomy is often greater than the
% resolution of the functional data (in the x-y plane, though usually not
% the number slices). Many functions duplicate this code. Better to put the
% function in one place. This is that place. 
%
% INPUTS
%   inplane: mrVista view inplane structure
%   ipAnatCoords: 3xn coords in inplane anatomical space
%   scan: scan number (integer). This argument has no effect since the
%           function upSampleFactor, which takes scan as an input does not
%           use scan. See notes in upSampleFactor.
%   preserveCoords: boolean. If true, size of output coords = size of input
%                   coords. If false, eliminate redundant voxels from
%                   output. Default = false.
%   preserveExactValues: boolean. If false, return integer coordinates. If
%                   true, return the calculated (non-integer values). 
% OUTPUTS
%   ipFuncCoords: 3xn coords in inplane functional space
%   inds        : 1xn vector of coordinate indices
%
% Example: (requires vistadata repository)
%   dataDir = fullfile(mrvDataRootPath,'functional','vwfaLoc');
%   cd(dataDir);
%   vw = initHiddenInplane();
%   vw = loadROI(vw, 'LV1.mat');
%   ipAnatCoords = viewGet(vw, 'ROI coords');
%   ipFuncCoords = ip2functionalCoords(vw, ipAnatCoords);
%
%
% JW 7/2010

if ~exist('scan', 'var') || isempty(scan),  scan            = 1;     end
if ~exist('preserveCoords', 'var'),         preserveCoords  = false; end
if ~exist('preserveExactValues', 'var'),preserveExactValues = false; end

% num voxels in
nVoxels  = size(ipAnatCoords, 2);

% scale factor
rsFactor = upSampleFactor(inplane, scan)';

% scale 'em
ipFuncCoords = ipAnatCoords ./ repmat(rsFactor, [1 nVoxels]);

% round unless exact values are requested. if non-integer values are
% returned, then the parent function will need to deal with them, e.g., via
% interpolation.
if ~preserveExactValues, ipFuncCoords = round(ipFuncCoords); end

% remove redunanant voxels
if ~preserveCoords
    [ipFuncCoords ia] = intersectCols(ipFuncCoords, ipFuncCoords); 
    
    % when we use intersectCols to remove redundant voxels, we also have
    % the undesired result of sorting voxels. to preserve the order of the
    % voxels, we need to unsort.
    [~, inds] = sort(ia);
    ipFuncCoords = ipFuncCoords(:, inds);
end

if nargout > 1
    if preserveExactValues
        error('Cannot return coordinate indices if coordinates have non-integer values. Call with preserveExactValues == 0')
    end
    
    sz = viewGet(inplane, 'data size');
    
    % convert the x,y,z coords into a vector of indices
    inds = sub2ind(sz, ...
        ipFuncCoords(1,:), ipFuncCoords(2,:), ipFuncCoords(3,:))';
end
return