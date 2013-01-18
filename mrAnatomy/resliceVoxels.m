function reslicedImg = resliceVoxels(imgCubeData, rowSpan, colSpan, planeSpan)
% Reslice voxels in a image volume - voxels become isotropic
%
%  reslicedImg = resliceVoxels(imgCubeData, rowSpan, colSpan, planeSpan)
%
% imgCubeData: original volume
% rowSpan, colSpan, and PlaneSpan: the linear distance spanned (in real units) by each
% of the dimensions in the image data. 
%
% If the image data span 240mm in the x and y dimensions and 148mm in the z
% dimension, then rowSpan = 240; colSpan = 240; planeSpan = 148 
% 
% resliceVoxels() returns a 3D matrix of voxel values.
%
%  Is this the modern routine?  Or has it been replaced? 2009.10.17 - BW

% Should be improved.
error(nargchk(4,4,nargin));

disp('Reslicing image to cubic voxels...');

[nRows,nCols,nPlanes] = size(imgCubeData);


disp('Determining voxel dimensions...');

mmPerVoxelInX = colSpan / nCols;
disp([num2str(mmPerVoxelInX) 'mm per voxel in the x axis.']);

mmPerVoxelInY = rowSpan / nRows;
disp([num2str(mmPerVoxelInX) 'mm per voxel in the y axis.']);

mmPerVoxelInZ = planeSpan / nPlanes;
disp([num2str(mmPerVoxelInZ) 'mm per voxel in the z axis.']);

%%
% Compute the target cubic dimension by finding the smallest dimension

targetDimension = min([mmPerVoxelInX mmPerVoxelInY mmPerVoxelInZ]);
disp(['All voxels will be resliced to be isotropic, ' num2str(targetDimension) 'mm per voxel.']);

% Compute number of slices in each dimension (rounded to the nearest integer).
numResampledSlicesX = round(colSpan / targetDimension);
numResampledSlicesY = round(rowSpan / targetDimension);
numResampledSlicesZ = round(planeSpan / targetDimension);

% Reslice the image. We do this in one step using inter3:

disp(['Resampling the x axis to ' int2str(numResampledSlicesX) ' slices...']);
disp(['Resampling the y axis to ' int2str(numResampledSlicesY) ' slices...']);
disp(['Resampling the z axis to ' int2str(numResampledSlicesZ) ' slices...']);

reslicedImg = interp3(imgCubeData, linspace(1,nCols,numResampledSlicesX),linspace(1,nRows,numResampledSlicesY)',linspace(1,nPlanes,numResampledSlicesZ)');

disp(['Volume dimensions are now: ' int2str(size(reslicedImg))]);

return;