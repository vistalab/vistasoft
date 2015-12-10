function [mmPerPix,volSize,fileName] = readVolAnatHeader(fileName)
% [mmPerPix,volSize,fileName,fileFormat] = readVolAnatHeader([fileName])
%
% Reads the header from the vAnatomy.dat file specified by fileName (full path!).
%
% If fileName is omitted, a get file dialog appears.
%
% If the mmPerPix is not found in the vAnatomy file header, this function will look 
% for an UnfoldParams.mat file in the same dir.  If it finds it, it will get the 
% mmPerPix from there.  
%
% RETURNS:
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * fileName is the full-path to the vAnatomy.dat file. (If 
%     you pass fileName in, you obviously don't need this. But 
%     it may be useful when the user selects the file.)
%   * fileFormat = 'dat' or 'nifti'
%
% 2001.02.20 RFD
% 2002.03.14 ARW Don't halt if mm per vox not found. Set to 1x1x1 and carry on with a warning.
% 2007.12.20 RFD Added support for NIFTI files.

if ~exist('fileName', 'var'), fileName = ''; end

% if fileName is empty, get the filename and path with a uigetfile
if isempty(fileName) || ~exist(fileName,'file')
    filterSpec = {'*.nii.gz;*.nii','NIFTI files';'*.*','All files'};
    [fname, fpath] = uigetfile(filterSpec, 'Select a vAnatomy file...');
    fileName = [fpath fname];
    if fname == 0
        % user cancelled
        return;
    end
    [fpath,fname,ext] = fileparts(fileName); %#ok<*ASGLU>
else
    [fpath,fname,ext] = fileparts(fileName);
end

% Check to see if this is a new NIFTI-format or old vAnatomy.dat format
if(strcmpi(ext,'.dat'))
    error('Please convert your volume anatomy to nifti.');
end

% Just load the header
ni = mrLoad(fileName, 'nifti');
mmPerPix = ni.voxelSize(1:3);
volSize = ni.dims(1:3);

return
