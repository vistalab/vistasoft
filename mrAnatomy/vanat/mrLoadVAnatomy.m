function [volume, sagSize, numSlices, calc, dataRange] = mrLoadVAnatomy(voldr,subject)
%
%  [volume, sagSize, numSlices, calc, dataRange] = mrLoadVAnatomy(voldr,subject)
%
% AUTHOR:  Engel, Boynton, Wandell
%
% Loads in anatomy in mrUnfold format.
%
% TODO:
%   Returns vSize, not sagSize,numSlices
%   Separate out the loading of anatomy and gray matter

if nargin<2
   volumeDataFile = voldr;
else
  volumeDataFile = [voldr,'/',subject,'/vAnatomy.dat'];   %Note the filename convention.
end

% Convert the volume anatomy into the vector format

%[volume vSize] = readVolume(volumeDataFile);
[volume,mmPerPix,vSize,fileName] = readVolAnat(volumeDataFile);
volume = createVolumeVector(volume(:)');
sagSize = [ vSize(1) vSize(2)]; 
numSlices = vSize(3);

%these are here for backwards compatibility.  They should go away someday.
calc = [];
dataRange = [1,numSlices];









