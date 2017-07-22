function itkClasses2roi(ni, labelFile)
% Convert multiple layers (classes) from a nifti segmentation file (created
% by itkGray) into mrVista Gray ROIs 
% 
% itkClasses2roi(ni, labelFile)
%
%   ni = path to a nifti class file (assumed to contain integer data
%           points)
%   labelfile: path to an itk label file
%
% Example:
%   ni        = fullfile(mrvDataRootPath, 'anatomy/anatomyNIFTI/t1_class.nii.gz')
%   labelfile = fullfile(mrvDataRootPath, 'anatomy/anatomyNIFTI/t1_class.lbl');
%   itkClasses2roi(ni, labelfile)
%
% see itkClass2roi.m, nifti2mrVistaAnat.m
 
error('Obsolete. Use nifti2ROI instead.')

if nargin < 1, help(mfilename); return; end

%% Remember where we start so we can clean up at the end
curdir = pwd;


%% Load the class file
if ~exist('ni', 'var') || ~exist(ni, 'file')
    [ni pth.ni] = uigetfile( ...
        {'*.gz', 'Nifti class files (*.gz)';'*.*', 'All files (*.*)'}, 'Select the itkGray classification file.');
    ni = fullfile(pth.ni, ni);
    cd(pth.ni);    
end

%% Load the label file
if ~exist('labelFile', 'var') || ~exist(labelFile, 'file')
    [labelFile pth.label] = uigetfile( '*.lbl', 'Select the itkGray label file.');
    labelFile = fullfile(pth.label, labelFile);
end

cd(curdir);

% convert text file into convenient matlab structure
labels      = itkGrayGetLabels(labelFile);

%% loop through the labels, and save each one as a separate roi
pth = fileparts(ni);
for ii = 1:numel(labels)
    if ~strcmpi('Clear Label', labels(ii).name)  
        % We skip 'Clear Label' as it is presumed empty
        itkClass2roi(ni, 'name', labels(ii).name, 'color',...
            labels(ii).col, 'layer', labels(ii).layer, 'spath', pth);
    end
end


