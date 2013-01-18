function [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = readIfileHeader(IFileName)
% [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = readIfileHeader(IFileName)
%
%   This functions serves the purpose to read headers of various types
% of Ifiles, including the traditional GE signa raw Ifiles, and the new
% Ifiles in DICOM (.dcm) format.
%   If the file name ends in digits (e.g. .001), it is taken as GE raw
% Ifiles and handled with GE_readHeader.m, and if the file name ends as
% .dcm, it is taken as DICOM files and handled with DICOM_readHeader.m
%   DICOM format contains less info than the raw GE Ifiles. Hence, the
% outputs of DICOM files has less fields. I have made sure that the outputs
% contain enough info for all VISTASOFT codes.
%
% Junjie Liu 2004/01/23
% 2005.06.27 RFD: added support for gzipped or zipped files.
% 2005.10.21 ras: imported into mrVista 2 repository.

[junk filename ext] = fileparts(IFileName);

% The following is slow, but works.
if(strcmp(lower(ext),'.gz') | strcmp(lower(ext),'.zip') & exist('gunzip.m','file'))
    td = tempname;
    switch(lower(ext))
        case '.gz',
            gunzip(IFileName, td);
        case '.zip',
            unzip(IFileName, td);
    end
    IFileName = fullfile(td, filename);
    [junk filename ext] = fileparts(IFileName);
end

if strcmp(ext,'.dcm');
    [su_hdr, ex_hdr, se_hdr, im_hdr, pix_hdr, im_offset] = ....
        DICOM_readHeader(IFileName);
else
    [su_hdr, ex_hdr, se_hdr, im_hdr, pix_hdr, im_offset] = ...
        GE_readHeader(IFileName);
end

if(exist('td','var')) rmdir(td, 's'); end

return
