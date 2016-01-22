function [vData,mmPerPix,volSize,fileName] = readVolAnat(fileName)
% Loads the vAnatomy nifti file specified by fileName (full path!)
%
% [img,mmPerPix,volSize,fileName] = readVolAnat([fileName])
%
% Dat are read into the [rows,cols,planes] image cube 'img'.
%
% If fileName is omitted, a get-file dialog appears.
%
% RETURNS:
%   * img is the [rows,cols,planes] intensity array
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * fileName is the full-path to the vAnatomy.dat file. (If
%     you pass fileName in, you obviously don't need this. But
%     it may be useful when the user selects the file.)
%
% 2000.01.28 RFD
% 2001.02.21 RFD: modified it to try the UnfoldParams.mat if the
%            mmPerPix was not found in the vAnatomy header. It also
%            now returns the full path with filename, rather than
%            just the directory.
% 8/29/2001 DJH: modified to remove redundancy with readVolAnatHeader
% 2001.08.28 RFD: fixed DJH's mod so that you once again call it without
%           specifying a filename.
% 2002.02.25 ARW Removed uint8 cast. Noone knows where this came from.
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

% ensure oriention is canonical
ni = niftiApplyCannonicalXform(ni);

% Scale intensities to 0-255 range
switch class(ni.data)
    case 'uint8'
        vData = double(ni.data);
    case 'int8'
        vData = double(ni.data)+127;
    otherwise
        % if possible, apply nifti-specified scale/slope and windowing
        if      checkfields(ni, 'scl_slope') && ...
                checkfields(ni, 'scl_inter') && ...
                checkfields(ni, 'cal_max') && ...
                checkfields(ni, 'cal_min')
            
            if ni.scl_slope~=0
                vData = ni.scl_slope * double(ni.data) + ni.scl_inter;
            else
                vData = double(ni.data) + ni.scl_inter;
            end
            if ~(ni.cal_max >0), ni.cal_max = max(vData(:)); end
            
            vData(vData<ni.cal_min) = ni.cal_min;
            vData(vData>ni.cal_max) = ni.cal_max;
            
        else
            vData =double(ni.data);
        end
        
        % put data in range [0 255]
        vData = vData-min(vData(:));
        vData = vData./max(vData(:)).*255;
end
% Flip voxel order to conform the vAnatomy spec
% NOTE: this assumes that the nifti data are in the cannonical axial
% orientation. If they might not be, call niftiAppyCannonicalXform.
% vAnatomy is [Z Y X] but the cannonical NFTI is [X Y Z], so we need to
% permute the dims. We also need to flip Z and Y.
vData = mrAnatRotateAnalyze(vData);


return
