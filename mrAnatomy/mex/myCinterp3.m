function myCinterp3
% 
% interpVolume = myCinterp3(volumeData, sliceDim, numSlices, samp, badval)
% 
% A much more efficient replacement for matlab's notoriously memory-eating interp3.
%
% volumeData: 3d array of the volume data of size [sliceDim(1), sliceDim(2), nslices].
% sliceDim:   in-plane dimensions [size(volumeData,1) size(volumeData,2)]
% numSlices:  number of slices [size(volumeData,3)]
% samp:       data points to interpolate with size Nx3. Note that these
%             coordinates should be one-indexed, just as with matlab's
%             interp3.
% badval:     value to put into voxels outside the original array (defaults to 0.0).
%
% returns the interpolated volume data.
%
% 
% HISTORY:
%  2002.08.21 RFD (bob@white.stanford.edu) wrote this help file, based on
%             Oscar's code.

disp('To compile, try:');
disp(['cd ' fileparts(which(mfilename)) '; mex -O ' mfilename '.c']);
error('This function must be compiled!');