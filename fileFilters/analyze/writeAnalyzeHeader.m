function numOut = writeAnalyzeHeader(fname, hdr, endianType)
%
% numOut = writeAnalyzeHeader(fname, hdr, [endianType])
%
% writes Analyze-format header
%
% fname   - filename 	     (e.g 'spm' or 'spm.img')
%
% numOut       - number of elements successfully written (should be 348)
%
% see also dbh.h (ANALYZE) spm_hread.m and spm_type.m
%

evalin('caller','mfilename');
disp('Obsolete writeAnalyzeHeader.  Use analyzeWriteHeader ');

% Default to little-endian
if ~exist('endianType','var') | isempty(endianType)
    endianType = 'ieee-le';
end

% ensure correct suffix {.hdr} and open header file
%
[p,f,e] = fileparts(fname);
fname = fullfile(p, [f '.hdr']);

fid = fopen(fname,'w',endianType);

if (fid == -1),
	error(['Error opening ' fname '. Check that you have write permission.']);
end;

%---------------------------------------------------------------------------
% if hdr.datatype == 1;   hdr.bitpix = 1;  hdr.glmax = 1;        hdr.glmin = 0;	end
% if hdr.datatype == 2;   hdr.bitpix = 8;  hdr.glmax = 255;      hdr.glmin = 0;	end
% if hdr.datatype == 4;   hdr.bitpix = 16; hdr.glmax = 32767;    hdr.glmin = 0;  	end
% if hdr.datatype == 8;   hdr.bitpix = 32; hdr.glmax = (2^31-1); hdr.glmin = 0;	end
% if hdr.datatype == 16;  hdr.bitpix = 32; hdr.glmax = 1;        hdr.glmin = 0;	end
% if hdr.datatype == 64;  hdr.bitpix = 64; hdr.glmax = 1;        hdr.glmin = 0;	end

%---------------------------------------------------------------------------

fseek(fid,0,'bof');

% write (struct) header_key
%
fwrite(fid, 348, 'int32');
fwrite(fid, fixLen(hdr.data_type, 10), 'char' );
fwrite(fid, fixLen(hdr.db_name,18), 'char' );
fwrite(fid, fixLen(hdr.extents,1), 'int32');
fwrite(fid, fixLen(hdr.session_error,1), 'int16');
fwrite(fid, fixLen(hdr.regular,1), 'char' );
fwrite(fid, fixLen(hdr.hkey_un0,1), 'char' );

% write (struct) image_dimension
%---------------------------------------------------------------------------
fseek(fid,40,'bof');

fwrite(fid, fixLen(hdr.dim,8), 'int16');
fwrite(fid, fixLen(hdr.vox_units,4), 'char' );
fwrite(fid, fixLen(hdr.cal_units,8), 'char' );
fwrite(fid, fixLen(hdr.unused1,1), 'int16' );
fwrite(fid, fixLen(hdr.datatype,1), 'int16');
fwrite(fid, fixLen(hdr.bitpix,1), 'int16');
fwrite(fid, fixLen(hdr.dim_un0,1), 'int16');
fwrite(fid, fixLen(hdr.pixdim,8), 'float');
fwrite(fid, fixLen(hdr.vox_offset,1), 'float');
fwrite(fid, fixLen(hdr.funused1,1),	'float');
fwrite(fid, fixLen(hdr.funused2,1),	'float');
fwrite(fid, fixLen(hdr.funused3,1), 'float');
fwrite(fid, fixLen(hdr.cal_max,1), 'float');
fwrite(fid, fixLen(hdr.cal_min,1), 'float');
fwrite(fid, fixLen(hdr.compressed,1), 'int32');
fwrite(fid, fixLen(hdr.verified,1), 'int32');
fwrite(fid, fixLen(hdr.glmax,1), 'int32');
fwrite(fid, fixLen(hdr.glmin,1), 'int32');

% write (struct) data_history
%---------------------------------------------------------------------------
fwrite(fid, fixLen(hdr.descrip,80),	'char');
fwrite(fid, fixLen(hdr.aux_file,24), 'char');
fwrite(fid, fixLen(hdr.orient,1), 'char');
fwrite(fid, fixLen(hdr.origin,5), 'int16');
fwrite(fid, fixLen(hdr.generated,10), 'uchar');
fwrite(fid, fixLen(hdr.scannum,10), 'uchar');
fwrite(fid, fixLen(hdr.patient_id,10), 'uchar');
fwrite(fid, fixLen(hdr.exp_date,10), 'uchar');
fwrite(fid, fixLen(hdr.exp_time,10), 'uchar');
fwrite(fid, fixLen(hdr.hist_un0,3), 'uchar');
fwrite(fid, fixLen(hdr.views,1), 'int32');
fwrite(fid, fixLen(hdr.vols_added,1), 'int32');
fwrite(fid, fixLen(hdr.start_field,1), 'int32');
fwrite(fid, fixLen(hdr.field_skip,1), 'int32');
fwrite(fid, fixLen(hdr.omax,1), 'int32');
fwrite(fid, fixLen(hdr.omin,1), 'int32');
fwrite(fid, fixLen(hdr.smax,1), 'int32');
fwrite(fid, fixLen(hdr.smin,1), 'int32');

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