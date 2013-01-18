function [vData,mmPerPix,volSize,fileName] = readVolAnat8bit(fileName)
% [img,mmPerPix,volSize,fileName] = readVolAnat([fileName])
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
[vData cnt] = fread(vFile,prod(volSize),'uint8=>uint8');
fclose(vFile);

% *** HACK!  Sometimes the vAnatomy is missing the last byte (???)
if length(vData) == prod(volSize)-1
   vData(end+1) = 0;
end

%img = uint8(zeros(volSize));

% Return vData permuted to maintain correct orientations. The old way was
% very inefficient.
%keyboard
%vData=reshape(vData,[volSize(1),volSize(2),volSize(3)]);
vData=reshape(vData,[volSize(2),volSize(1),volSize(3)]);
vData=permute(vData,[2,1,3]);
volSize=size(vData);



% 
% slicePix = volSize(1)*volSize(2);
% for ii=0:volSize(3)-1
%    img(:,:,ii+1) = reshape(vData(ii*slicePix+1:ii*slicePix+slicePix),[volSize(2) volSize(1)])';
% end

return
