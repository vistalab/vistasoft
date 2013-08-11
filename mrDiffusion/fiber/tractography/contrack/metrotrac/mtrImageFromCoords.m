function [vol] = mtrImageFromCoords(coords1, coords2, volExFile, volOutFile)
%Create ROI image mask from two sets of coordinates.
%
%   [vol] = mtrImageFromCoords(coords1, coords2, volExFile,
%                                   volOutFile)
%   
%   coords1, coords2: Points in AcPc space.
%   volExFile: Example volume file that defines the image space.
%   volOutFile: Our output.
%
% NOTES: 
%   * TrackVis file is in mm coordinates, but without center shift
%   * PDB file is loaded in AcPc coordinates.


% Load vol file to get AcPc xform
vol = niftiRead(volExFile);
xformFrom = vol.qto_ijk;

% Set the volume structure for output now
vol.fname = '';
vol.data = zeros(size(vol.data));

% Transform the coords
if ~isempty(coords1)
    imgCoords = floor(mrAnatXformCoords(xformFrom, coords1))';
    inds = sub2ind(size(vol.data),imgCoords(1,:), imgCoords(2,:), imgCoords(3,:));
    vol.data(inds) = 1;
end
if ~isempty(coords2)
    imgCoords = floor(mrAnatXformCoords(xformFrom, coords2))';
    inds = sub2ind(size(vol.data),imgCoords(1,:), imgCoords(2,:), imgCoords(3,:));
    vol.data(inds) = 2;
end

% Write output image 
if ~ieNotDefined('volOutFile')
    vol.fname = volOutFile;
    writeFileNifti(vol);
end

return;
