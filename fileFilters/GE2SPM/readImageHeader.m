function [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = readImageHeader(IFileName)
% [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = readImageHeader(IFileName)
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
% ARW 2004/03/08 : Changed name. 

[junk filename ext] = fileparts(IFileName);

if strcmp(lower(ext),'.dcm');
    disp('Reading DICOM');
    [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = DICOM_readHeader(IFileName);
elseif ~isempty(str2num(ext(2:end)));
    disp('Reading GE');

    [su_hdr,ex_hdr,se_hdr,im_hdr,pix_hdr,im_offset] = GE_readHeader(IFileName);
else
    error('Unknown Ifile format');
end

return
