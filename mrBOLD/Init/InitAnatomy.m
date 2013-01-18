function [anat, inplanes, doCrop] = InitAnatomy(homeDir, rawDir, doCrop)
% Find and load the anat data files
%
% [anat, inplanes, doCrop] = InitAnatomy(homeDir, rawDir, doCrop);
%
% Based on the doCrop input, either just find the anatomy, or scan the raw
% anatomy images files to create an uncropped anatomy.
%
% INPUTS
%   rawDir  
%   homeDir
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
% ras 1/04: added code to make it behave more sensibly w.r.t. cropping;
% it will no longer change the value of doCrop if no anatomy file is found
% (in other words, if you don't select cropping during the first dialog,
% it won't make you crop anyway.) Will automatically set crop values to
% full size of the anatomicals in this case.

if doCrop
    anatFile = fullfile(homeDir, 'Inplane', 'anat.mat');
    needAnatFile = ~exist(anatFile, 'file');
    if ~needAnatFile
        % load anat matrix and inplanes structure
        load(anatFile);
        needAnatFile = ~exist('anat', 'var') | ~exist('inplanes', 'var');
    end
else
    % If the user hasn't explicitly requested an inplane crop,
    % try to find an extant anat.mat file:
    anatFile = fullfile(homeDir, 'Inplane', 'anat.mat');
    needAnatFile = ~exist(anatFile, 'file');
    if ~needAnatFile
        % load anat matrix and inplanes structure
        load(anatFile);
        needAnatFile = ~exist('anat', 'var') | ~exist('inplanes', 'var');
    end 
end


if needAnatFile
    % If there's still no usable anat.mat file, scan the 
    % inplane-anatomy images:
    anatDir = fullfile(rawDir, 'Anatomy', 'Inplane');
    [anat, inplanes] = GetAnatomy(anatDir);
    if isempty(anat)
        Alert('Could not find inplane anatomy');
    end
end

return