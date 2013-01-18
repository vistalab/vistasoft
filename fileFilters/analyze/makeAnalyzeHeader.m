function hdr = makeAnalyzeHeader(datatype, fname)
%
% hdr = makeAnalyzeHeader(datatype, fname)
%
% makes an Analyze-format header struct with many default values pre-loaded.
%
%
%

if(~exist('datatype','var') | isempty(datatype))
    datatype = 4;
end
if(~exist('fname','var') | isempty(fname))
    fname = 'unknown';
end

% compute intensity range & bits per pix from datatype
%
glmin = 0;
switch(datatype)
case 1,
    bitpix = 1;
    glmax = 1;
case 2,
    bitpix = 8;
    glmax = 255;
case 4,
    bitpix = 16;
    glmax = 32767;
case 8,
    bitpix = 32;
    glmax = (2^31-1);
case 16,
    bitpix = 32;
    glmax = 1;
case 64,
    bitpix = 64;
    glmax = 1;
otherwise,
    error(['Unknown datatype ',num2str(datatype),'!']);
end

hdr.data_type = fixLen('dsr', 10);
hdr.db_name = fixLen(fname,18);
hdr.extents = 16384; % Should be 16384, the image file is created as contiguous with a minimum
hdr.session_error = 0;
hdr.regular = 'r';   % Must be `r' to indicate that all images and volumes are the same size.
hdr.hkey_un0 = 0;

% write (struct) image_dimension
%
hdr.dim = fixLen(dim,8);
hdr.vox_units = fixLen('mm',4);
hdr.cal_units = fixLen(' ',8);
hdr.unused1 = fixLen(0,1);
hdr.datatype = fixLen(datatype,1);
hdr.bitpix = fixLen(bitpix,1);
hdr.dim_un0 = fixLen(0,1);
hdr.pixdim = fixLen(pixdim,8);
hdr.vox_offset = fixLen(vox_offset,1);
hdr.funused1 = fixLen(funused1,1);
hdr.funused2 = fixLen(funused2,1);
hdr.funused3 = fixLen(funused3,1);
hdr.cal_max = fixLen(cal_max,1);
hdr.cal_min = fixLen(cal_min,1);
hdr.compressed = fixLen(compressed,1);
hdr.verified = fixLen(verified,1);
hdr.glmax = fixLen(glmax,1);
hdr.glmin = fixLen(glmin,1);

% write (struct) data_history
%---------------------------------------------------------------------------
hdr.descrip = fixLen(descrip,80),	'char');
hdr.aux_file = fixLen(aux_file,24), 'char');
% valid values for orient:
% 0 transverse unflipped, 1 coronal unflipped, 2 sagittal unflipped,
% 3 transverse flipped, 4 coronal flipped, 5 sagittal flipped
hdr.orient = fixLen(orient,1), 'char');
hdr.origin = fixLen(origin,5), 'int16');
hdr.generated = fixLen(generated,10), 'uchar');
hdr.scannum = fixLen(scannum,10), 'uchar');
hdr.patient_id = fixLen(patient_id,10), 'uchar');
hdr.exp_date = fixLen(exp_date,10), 'uchar');
hdr.exp_time = fixLen(exp_time,10), 'uchar');
hdr.hist_un0 = fixLen(hist_un0,3), 'uchar');
hdr.views = fixLen(views,1), 'int32');
hdr.vols_added = fixLen(vols_added,1), 'int32');
hdr.start_field = fixLen(start_field,1), 'int32');
hdr.field_skip = fixLen(field_skip,1), 'int32');
hdr.omax = fixLen(omax,1), 'int32');
hdr.omin = fixLen(omin,1), 'int32');
hdr.smax = fixLen(smax,1), 'int32');
hdr.smin = fixLen(smin,1), 'int32');

numOut = ftell(fid);
fclose(fid);
return;

function m = fixLen(m, len)
m = m(:)';
if(length(m) > len)
    m = m(1:len);
elseif(length(m) < len)
    if(ischar(m))
        m = [m char(zeros(1,len-length(m)))];
    else
        m = [m zeros(1,len-length(m))];
    end
end
return