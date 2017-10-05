function [vData,mmPerPix,volSize,fileName, ni] = readVolAnat(fileName)
% Loads the vAnatomy nifti file specified by fileName (full path!)
%
% [img,mmPerPix,volSize,fileName, ni] = readVolAnat([fileName])
%
% Dat are read into the [rows,cols,planes] image cube 'img'.
%
% If fileName is omitted, a get-file dialog appears.
%
% RETURNS:
%   * vData is the [rows,cols,planes] intensity array
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * volSize is the number of voxels in the image (rows, cols, planes)
%   * fileName is the full-path to the vAnatomy file. (If
%     you pass fileName in, you obviously don't need this. But
%     it may be useful when the user selects the file.)
%   * ni is the nifti structure
% 
% 2000.01.28 RFD
% 2001.02.21 RFD: modified it to try the UnfoldParams.mat if the
%            mmPerPix was not found in the vAnatomy header. It also
%            now returns the full path with filename, rather than
%            just the directory.
% 8/29/2001 DJH: modified to remove redundancy with readVolAnatHeader
% 2001.08.28 RFD: fixed DJH's mod so that you once again call it without
%           specifying a filename.
% 2002.02.25 ARW Removed uint8 cast. No one knows where this came from.
% read header
% ARW 2003.01.09 Replacing uint8 casts for improved memory usage.
% 2007.12.20 RFD Added support for NIFTI files.
%
%
% See also:  How to convert a vAnatomy to a NIFTI format.
%
% (c) Stanford VISTA Team 2000

if(~exist('fileName','var'))
    [mmPerPix,volSize,fileName] = readVolAnatHeader;
else
    [mmPerPix,volSize,fileName] = readVolAnatHeader(fileName);
end

% Load the vANATOMY
ni = niftiRead(fileName);

% Reorient
vData = nifti2mrVistaAnat(ni);

return
