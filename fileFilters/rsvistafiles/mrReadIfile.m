function [img, header] = mrReadIfile(filename);
% [img, header] = mrReadIfile(filename)
%
% Read either a DICOM file or Genesis I* file, returning 
% the MR image and the header info.
%
% ras, 07/05 -- imported into mrVista 2.0

% Coding history (ReadMRImage):
% Ress 4/99 Rewritten from readMRImage in the mrLoadRet2.0 distribution.
% dicom format. So we need to add a path for reading dicom files here...
% For now, let's try to read as a dicom file. If we fail, we assume we're
% in the world of GEMS...
% AG 10/19/2004 the field SpacingBetweeenSlices does not seem to be present
% in the dicom files output by Siemens Magneton 3T. Added "if isfield" test 
% and put arbitrary value of 4 as a fallback default. line 53
% JL 01/23/2005 do not try header unless asked for -- to avoid unnecessary error in reading dicom headers.

try
    dheader=dicominfo(filename);
    isDicom=1;
catch
    isDicom=0;
end

if (isDicom)
    img=dicomread(dheader);
    %disp('Read DICOM');
    % Generate a valid header from the DICOM header
    % we need:
    % .image, .exam, .suite, .series, pixel and .offset
    % Each of these in turn has some subfields . They are:
    % image.dfov
    % image.imatrix_X, image.imatrix_Y, image.slthick, image.scanspacing,
    % exam.ex_no
    if nargout > 1       
        % Get the header information:
        [su_hdr, ex_hdr, se_hdr, im_hdr, pix_hdr, im_offset] = ...
            readIfileHeader(filename);
        header.suite = su_hdr;
        header.exam = ex_hdr;
        header.series = se_hdr;
        header.image = im_hdr;
        header.pixel = pix_hdr;
        header.offset = im_offset;
            
        % disabled, will probably remove; we do parsing of the
        % header format in mrReadDicomDir and mrReadIfileDir.
%         header.suite=[];
%         header.pixel=[];
%         header.series=[];
%         header.offset=[];
%         i.dfov=dheader.PixelSpacing(1)*dheader.Width;
%         i.imatrix_X=dheader.Width;
%         i.imatrix_Y=dheader.Height;
%         i.slthick=dheader.SliceThickness;
%         if isfield(dheader,'SpacingBetweenSlices')
%             i.scanspacing=dheader.SpacingBetweenSlices; % Note this could also be 'SpacingBetweenSlices-slthick)
%         else i.scanspacing=4; end
%         header.image=i;
%         e.ex_no=dheader.StudyID;
%         header.exam=e;
    end
    
    
else 
    img=readRawImage(filename);
    
    if nargout > 1;
        % Get the header information:
        [su_hdr, ex_hdr, se_hdr, im_hdr, pix_hdr, im_offset] = ...
            readIfileHeader(filename);
        header.suite = su_hdr;
        header.exam = ex_hdr;
        header.series = se_hdr;
        header.image = im_hdr;
        header.pixel = pix_hdr;
        header.offset = im_offset;
        
        imageSize = [pix_hdr.img_height pix_hdr.img_width];
        if any(prod(imageSize(:)) ~= length(img(:)))
            disp(['Error in ReadMRImage: expected image size does not match data in ', filename]);
            img = []; header = []; return;
        end
    end
end
img(find(img>32767)) = (0); % zeros(size(find(img>32767)));

%img = reshape(img, imageSize(1), imageSize(2))';

return
