function [img, mmPerPix, vSize, filename, formatStr] = loadVolumeDataAnyFormat(filename)
% Load in MRI volumes from data in different formats
% 
%    [img, mmPerPix, vSize, filename, formatStr] = loadVolumeDataAnyFormat([filename])
% 
% Inputs:
%    filename: a string specifying the location of the file (if empty,
%    it'll ask for a file through uigetfile.)
% 
% Outputs:
%    1. img       - image data, X x Y x Z matrix
%    2. mmPerPix  - image spatial resolution, 1 x 3 vector
%    3. vSize     - dimension of the volume, 1 x 3 vector
%    4. filename  - file name of the data set, string
%    5. formatStr - format of the data, 'vanat', 'analyze' or 'nifti'
% 
% History:
%    ####/##/## created.
%    2007/02/05 shc added option for loading nifti, and help comments.
% 

img       = [];
mmPerPix  = [];
vSize     = [];
formatStr = '';

if ieNotDefined('filename')
    [fName, fPath] = uigetfile( ...
        { '*.dat',          'mrGray vAnatomy (*.dat)'; ...
          '*.hdr',          'Analyze 7.5 format (*.hdr)'; ...
          '*.nii;*.nii.gz', 'Nifti format (*.nii, *.nii.gz)' }, ...
        'Select a volume file ...');
end

if fName == 0, disp('User cancelled!'); return; end

filename = fullfile(fPath,fName);

[pp,ff,ext] = fileparts(filename);

switch lower(ext)
    case '.dat' % vAnatomy
        [img, mmPerPix, vSize] = readVolAnat(filename);
        formatStr              = 'vanat';
    case '.hdr' % Analyze
        [img, mmPerPix] = loadAnalyze(filename);
        vSize           = size(img);
        formatStr       = 'analyze';
    case {'.nii','.gz'} % Nifti
        nii       = niftiRead(filename);
        img       = double(nii.data);
        mmPerPix  = nii.pixdim;
        vSize     = size(img);
        formatStr = 'nifti';
    otherwise
        error('Unknown format!');
end

% switch formatStr
%     case {'analyze','nifti'}
%         % to make analyze or nifti data the same orientation as vAnatomy, we swap dims and then
%         % flip along the new y and x.
%         % Note that we assume Analyze orientation code '0'- transverse, unflipped.
%         img      = permute(img,[3,1,2]);
%         mmPerPix = mmPerPix([3,1,2]);
%         % flip each slice ud (ie. flip along matlab's first dimension, which is our x-axis)
%         for jj = 1:vSize(3)
%             img(:,:,jj) = flipud(squeeze(img(:,:,jj)));
%         end
%         % flip each slice lr(ie. flip along matlab's second dimension, which is our y-axis)
%         for jj = 1:vSize(3)
%             img(:,:,jj) = fliplr(squeeze(img(:,:,jj)));
%         end
% end

return
