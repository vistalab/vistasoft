function [vData,mmPerPix,volSize,fileName] = readFileVAnat(fileName)
% Read in a mrGray vAnatomy .dat file.
%
% [img,mmPerPix,volSize,fileName] = readFileVAnat([fileName])
%
% Loads the vAnatomy.dat file specified by fileName (full path!)
% into the [rows,cols,planes] image cube 'img'.
%
% If fileName is omitted, a get file dialog appears.
%
% RETURNS:
%   * img is the [rows,cols,planes] intensity array
%   * mmPerPix is the voxel size (in mm/pixel units)
%   * fileName is the full-path to the vAnatomy.dat file. (If 
%     you pass fileName in, you obviously don't need this. But 
%     it may be useful when the user selects the file.)
%
% ras, 06/30/05: imported into mrVista 2.0 Test repository.
% ras, 07/05: shuffled names a bit more: this is called 'readFileVAnat'
% since it reads the volume but doesn't create an mr struct.
if(~exist('fileName','var'))
    [mmPerPix,volSize,fileName] = readVolAnatHeader;
else
    [mmPerPix,volSize,fileName] = readVolAnatHeader(fileName);
end

% open file for reading (little-endian mode)
vFile = fopen(fileName,'r');
if vFile==-1
   img = [];
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
%keyboard

vData=reshape(vData,[volSize(2),volSize(1),volSize(3)]);
vData=double(permute(vData,[2,1,3])); % This double cast is required for routines that expect readVolAnat to return a double. 
                                       % mrLoadRet now uses 8-bit anatomy data and calls
                                    % readVolAnat8bit
%volSize=size(vData);
                                    
% 
% slicePix = volSize(1)*volSize(2);
% for ii=0:volSize(3)-1
%    img(:,:,ii+1) = reshape(vData(ii*slicePix+1:ii*slicePix+slicePix),[volSize(2) volSize(1)])';
% end

return
