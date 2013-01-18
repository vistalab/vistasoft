function [anat, inplanes, doCrop] = InitAnatomyDicom(homeDir, rawDir, anatDir, doCrop)
% [anat, inplanes, doCrop] = InitAnatomy(homeDir, rawDir, anatDir, doCrop);
%
% Based on the doCrop input, either find and load the anat file
% or scan the raw anatomy images files to create an uncropped
% anatomy.
%
% INPUTS
%   rawDir  
%   homeDir
% AnatDir: The directory containing the actual (DICOM format) images.
%   doCrop  A binary flag: If set, then always attempt to scan
%           the raw anatomies, and report and error if they can't
%           be found. If not set, try to load the anat file first,
%           and scan the raw anatomies if the former isn't successful.
%
% OUTPUT
%   anat    3D anatomy array
%   doCrop  Binary flag: if set, anatomy should be cropped.
%   inplanes structure containing info about the inplanes
%     FOV
%     fullSize
%     voxelSize
%     nSlices
%     crop
%     cropSize
%
% DBR  6/99
if ~doCrop
    % If the user hasn't explicitly requested an inplane crop,
    % try to find an extant anat.mat file:
    anatFile = fullfile(homeDir, 'Inplane', 'anat.mat');
    doCrop = ~exist(anatFile, 'file');
    if ~doCrop
        % load anat matrix and inplanes structure
        load(anatFile);
        doCrop = ~exist('anat', 'var') | ~exist('inplanes', 'var');
    end
end
if doCrop
    % If explicit request or no usable anat.mat file, scan the 
    % inplane-anatomy images:
    anatDir = fullfile(rawDir,anatDir);
    fprintf('\nLooking for anatomy files in %s\n',anatDir);
    
    [anat, inplanes] = GetAnatomy(anatDir);
    if isempty(anat)
        Alert('Could not find inplane anatomy');
    end
end
