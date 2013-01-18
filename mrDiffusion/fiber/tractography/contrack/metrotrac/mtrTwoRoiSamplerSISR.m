function mtrTwoRoiSamplerSISR(localSubDir, roi1File, roi2File, inSamplerOptsFile, outSamplerOptsFile, fgFile, roisMaskFile, scriptFileName, remoteSubDir, machineList)
% Runs first pass of SISR (Sequential Importance Sampling and Resampling) version of 
% ConTract (aka MetroTrac) for generating a distribution of pathways
% between 2 ROIs. This function requires mtrEC2Tensor to have been run in
% the local subject directory so that we can search for standard files.
% 
%  mtrTwoRoiSamplerSISR([localSubDir], [roi1File], [roi2File], [inSamplerOptsFile], [outSamplerOptsFile], [fgFile], [roisMaskFile], [scriptFileName], [remoteSubDir])
%
% INPUT
% roi1File, roi2File: List of coordinates in ACPC space that specify two
%   regions of interest in our DTI data that we would like to find pathways
%   connecting between.  These points are turned into a binary mask image
%   by
%   setting all voxels, with diffusion image resolution, to 1 that contain
%   an roi point. At this time the ROIs must not have any voxels in common.
% inSamplerOptsFile: Contains the parameters to run the ConTract algorithm.
%   Can use mtrCreate() in order to make a default file.
%
% OUTPUT
% fgFile: Pathway file for storing the database of pathways that connect
%   the two ROIs.
% roisMaskFile: Binary image containing non-zero voxels where the ROIs were
%   defined and zero elsewhere.
%
% Examples:
%
% AJS
%

mtrCreateConTrackOptionsFromROIs(localSubDir, roi1File, roi2File, inSamplerOptsFile, outSamplerOptsFile, fgFile, roisMaskFile, scriptFileName, remoteSubDir, machineList);
mtrPaths(mtr, dt6.xformToAcPc, fullfile(localSubDir,'conTrack',outSamplerOptsFile), fullfile(localSubDir,'conTrack',fgFile));
