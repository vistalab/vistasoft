function [img,header] = readRawImage(filename,header,imageSize,byteFlag)
%[img,header] = readRawImage(filename,[header],[imageSize],byteFlag)
%
%	filename is a string
%	imageSize is a vector of x and y sizes
%       header is a flag:
%	  if header = 1 then it uses the new header size of 7904
%	  if header = 2 then it uses the older header size of 7900
%         if imageSize is not given, readMRImage assumes that the
%         image is square with dimensions a power of two.  
%         if header = 0 or is not given readMRImage assumes that
%         Any extra data beyond imageSize is header material.

%4/10/98  gmb    Wrote it from myRead
%9/18/98  rmk    Added byteFlag which is a string passed to fopen to
%                control the byte-reading convention.  To read hp
%                format on a pc use byteFlag='b'
%2004.01.24 Junjie: If .dcm format of filename, use dicomread
%2004.09.01 RFD: changed fread type from 'ushort' to 'int16', which is what
%           GE uses.
% 2005.06.27 RFD: added support for gzipped or zipped files.

if ~exist('header','var') | isempty(header)
    header = 0;
end

if ~exist('byteFlag','var')
    byteFlag='b';
end

% % check to see if running on a pc:
% if (strcmp(computer,'GLNX86'))
%     pc=1;
% else
%     pc=0;
% end

[junk fn ext] = fileparts(filename);
% The following is slow, but works.
if(strcmp(lower(ext),'.gz') | strcmp(lower(ext),'.zip') & exist('gunzip.m','file'))
    td = tempname;
    switch(lower(ext))
        case '.gz',
            gunzip(filename, td);
        case '.zip',
            unzip(filename, td);
    end
    filename = fullfile(td, fn);
    [junk fn ext] = fileparts(filename);
end


% Check for DICOM format
if strcmp(ext,'.dcm');
    img = dicomread(filename);
else
    % If not DICOM, try to read as GE
    fid = fopen(filename,'r',byteFlag);

    if fid == -1
        disp(sprintf('Could not open file %s',filename));
        img = [];
        header = 0;
        return
    end
    %strip off header
    switch header
        case  0
            %deal with this later
        case  1 				%There is a header
            fseek(fid,7904,'bof');%Move start 7904 bytes from start of file
        case 2
            fseek(fid,7900,'bof');%Move start 7904 bytes from start of file
        otherwise
            fprintf('\nStrange header type found : =%d',header);
            fseek(fid,header,'bof');%Move start <header> bytes from start of file
    end

    %read in the rest of the file
    img = fread(fid,'int16');
    fclose(fid);

    %if imageSize not given, assume that it is the nearest power of 2
    if ~exist('imageSize','var') | isempty(imageSize)
        imageSize  = repmat(2^floor(log2(sqrt(length(img)))),1,2);
    end

    %if header is not given, estimate it from the difference
    %between the image size and the length of img.
    imageSize = double(imageSize);
    if ~header
        %crop off header
        header = (length(img)-prod(imageSize))*2;
        img = img(header/2+1:length(img));
    end

    if (prod(imageSize(:)) ~= length(img))
        disp(['*** Error in readMRImage:  imageSize does not match loaded image ''',filename,'''.']);
        img = [];
    end

    img(img>32767) = 0;
    img = reshape(img,imageSize(1),imageSize(2))';
end

% Delete temporary uncompressed file, if it exists
if(exist('td','var')) rmdir(td, 's'); end
return;
