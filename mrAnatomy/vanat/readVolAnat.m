function [vData,mmPerPix,volSize,fileName] = readVolAnat(fileName)
% Loads the vAnatomy.dat file specified by fileName (full path!)
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
    [mmPerPix,volSize,fileName,fileFormat] = readVolAnatHeader;
else
    [mmPerPix,volSize,fileName,fileFormat] = readVolAnatHeader(fileName);
end

if(strcmpi(fileFormat,'nifti'))
    % Just load the header
    ni = mrLoad(fileName, 'nifti');
    % Scale intensities to 0-255 range
    switch class(ni.data)
        case 'uint8'
            vData = double(ni.data);
        case 'int8'
            vData = double(ni.data)+127;
        otherwise
            % if possible, apply nifti-specified scale/slope and windowing
            if      checkfields(ni, 'hdr', 'scl_slope') && ...
                    checkfields(ni, 'hdr', 'scl_inter') && ...
                    checkfields(ni, 'hdr', 'cal_max') && ...
                    checkfields(ni, 'hdr', 'cal_min')

                if ni.hdr.scl_slope~=0
                    vData = ni.hdr.scl_slope * double(ni.data) + ni.hdr.scl_inter;
                else
                    vData = double(ni.data) + ni.hdr.scl_inter;
                end
                if ~(ni.hdr.cal_max >0), ni.hdr.cal_max = max(vData(:)); end
                
                vData(vData<ni.hdr.cal_min) = ni.hdr.cal_min;
                vData(vData>ni.hdr.cal_max) = ni.hdr.cal_max;
            
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
else
    % Load old vAnatomy format

    % open file for reading (little-endian mode)
    vFile = fopen(fileName,'r');
    if vFile==-1
        myErrorDlg(['Couldn''t open ',fileName,'!'])
        return;
    end

    % skip over header (already read it and checked that it was valid in readVolAnatHeader)
    nextLine = fgets(vFile);
    nextLine = fgets(vFile);
    nextLine = fgets(vFile);
    nextLine = fgets(vFile);

    % read volume
    [vData cnt] = fread(vFile,prod(volSize),'uint8');
    fclose(vFile);

    % *** HACK!  Sometimes the vAnatomy is missing the last byte (???)
    if length(vData) == prod(volSize)-1
        vData(end+1) = 0;
    end
    
    % Return vData permuted to maintain correct orientations. The old way was
    % very inefficient.
    vData=reshape(vData,[volSize(2),volSize(1),volSize(3)]);
    vData=double(permute(vData,[2,1,3])); % This double cast is required for routines that expect readVolAnat to return a double.
end

return
