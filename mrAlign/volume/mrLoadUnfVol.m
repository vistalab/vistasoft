function [volume, sagSize, numSlices, calc, dataRange] = mrLoadUnfVol()
%
%  [volume, sagSize, numSlices, calc, dataRange] = mrLoadUnfVol()
%
% AUTHOR:  Engel, Boynton, Wandell
%
% Loads in anatomy in mrUnfold format.
%
% TODO:
%   Returns vSize, not sagSize,numSlices
%   Separate out the loading of anatomy and gray matter
%   This routine should be called through the preferences at
%    start up, and it should run only once for each scan
%   The information obtained here goes with a subject's brain.
%    So, this routine should probably just take a subject's identifier
%    as input and go to the right directory and get the relevant
%    information all at once instead of bothering me.  That directory
%    should contain all the relevant information about the anatomies.


% Ask user for the volume anatomy data file
%
volumeDataFile = input('Enter volume anatomy data file: ','s');

% Convert the volume anatomy into the vector format
%
[volume vSize] = readVolume(volumeDataFile);

volume = createVolumeVector(volume');
sagSize = [ vSize(1) vSize(2)]; 
numSlices = vSize(3);

% This loads the locations of the gray matter within
% the anatomical volume.  We are not currently using gray-matter,
% though we will.  This should be around in a separate module.
%
%grayDataFile = input('Enter gray matter data file: ','s');
%[calc vSize] = readVolume(grayDataFile);
%calc = replaceValue(calc,2,1);
%calc = createVolumeVector(calc');
calc = [];

% This is probably unnecessary ... we would like to make this
% variable go away.
%
dataRange = [1,numSlices];
