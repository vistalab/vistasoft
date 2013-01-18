function hdr = analyzeReadHeader(fname)
% 
% hdr = analyzeReadHeader(fname);
%
% reads a raw Analyze-format header.
%
% fname - filename (e.g anat or anat.img or anat.hdr)
% hdr   - struct with most (maybe all?) of the analyze fields.
%
% Examples:
%   hdr = readAnalyzeHeader;
%
% SEE ALSO: dbh.h (ANALYZE) spm_hwrite.m and spm_type.m
% How do you read the data?
%
% HISTORY:
% 2002.07.23 RFD (bobd@stanford.edu) wrote it, based heavily on SPM's spm_hread.m. 
% 

if ieNotDefined('fname'), 
    fname = mrvSelectFile('r','hdr'); 
    if isempty(fname), return; end 
end

% ensure correct suffix {.hdr}
%
[p,f,e] = fileparts(fname);
fname = fullfile(p, [f '.hdr']);

% open header file- try little-endian first
%
fid = fopen(fname,'r','ieee-le');

if (fid < 0)
    error(['Could not open the header file ' fname '.']);
    hdr = [];
    return;
end

% read (struct) header_key
%
fseek(fid,0,'bof');

bigendian = 0;
sizeof_hdr 	= fread(fid,1,'int32');
if sizeof_hdr==1543569408, % Appears to be big-endian
    % Re-open big-endian
    fclose(fid);
    fid = fopen(P,'r','ieee-be');
    fseek(fid,0,'bof');
    sizeof_hdr = fread(fid,1,'int32');
    bigendian = 1;
end;

hdr.data_type     = mysetstr(fread(fid,10,'uchar'))';
hdr.db_name       = mysetstr(fread(fid,18,'uchar'))';
hdr.extents       = fread(fid,1,'int32');
hdr.session_error = fread(fid,1,'int16');
hdr.regular       = mysetstr(fread(fid,1,'uchar'))';
hdr.hkey_un0      = mysetstr(fread(fid,1,'uchar'))';

% read (struct) image_dimension
%---------------------------------------------------------------------------
fseek(fid,40,'bof');

hdr.dim    		= fread(fid,8,'int16');
hdr.vox_units   = mysetstr(fread(fid,4,'uchar'))';
hdr.cal_units   = mysetstr(fread(fid,8,'uchar'))';
hdr.unused1		= fread(fid,1,'int16');
hdr.datatype	= fread(fid,1,'int16');
hdr.bitpix		= fread(fid,1,'int16');
hdr.dim_un0		= fread(fid,1,'int16');
hdr.pixdim		= fread(fid,8,'float');
hdr.vox_offset	= fread(fid,1,'float');
hdr.funused1	= fread(fid,1,'float');
hdr.funused2	= fread(fid,1,'float');
hdr.funused3	= fread(fid,1,'float');
hdr.cal_max		= fread(fid,1,'float');
hdr.cal_min		= fread(fid,1,'float');
hdr.compressed	= fread(fid,1,'int32');
hdr.verified	= fread(fid,1,'int32');
hdr.glmax		= fread(fid,1,'int32');
hdr.glmin		= fread(fid,1,'int32');

% read (struct) data_history
%---------------------------------------------------------------------------
fseek(fid,148,'bof');

hdr.descrip		= mysetstr(fread(fid,80,'uchar'))';
hdr.aux_file	= mysetstr(fread(fid,24,'uchar'))';
hdr.orient		= fread(fid,1,'uchar');
hdr.origin		= fread(fid,5,'int16');
hdr.generated	= mysetstr(fread(fid,10,'uchar'))';
hdr.scannum		= mysetstr(fread(fid,10,'uchar'))';
hdr.patient_id	= mysetstr(fread(fid,10,'uchar'))';
hdr.exp_date	= mysetstr(fread(fid,10,'uchar'))';
hdr.exp_time	= mysetstr(fread(fid,10,'uchar'))';
hdr.hist_un0	= mysetstr(fread(fid,3,'uchar'))';
hdr.views		= fread(fid,1,'int32');
hdr.vols_added	= fread(fid,1,'int32');
hdr.start_field	= fread(fid,1,'int32');
hdr.field_skip	= fread(fid,1,'int32');
hdr.omax		= fread(fid,1,'int32');
hdr.omin		= fread(fid,1,'int32');
hdr.smax		= fread(fid,1,'int32');
hdr.smin		= fread(fid,1,'int32');

fclose(fid);

if isempty(hdr.smin)
    error(['There is a problem with the header file ' fname '.']);
end

% convert to SPM global variables
% %---------------------------------------------------------------------------
% DIM    	  	= dim(2:4)';
% VOX       	= pixdim(2:4)';
% SCALE     	= funused1;
% SCALE    	= ~SCALE + SCALE;
% TYPE     	= datatype;
% % *** FIX THIS
% if otherendian == 1 & datatype ~= 2,
% 	TYPE = TYPE*256;
% end;
% OFFSET	  	= vox_offset;
% ORIGIN    	= origin(1:3)';
% DESCRIP   	= descrip(1:max(find(descrip)));
% 
% else
% 	global DIM VOX SCALE TYPE OFFSET ORIGIN
% 	DESCRIP = ['defaults'];
% end
return;
%_______________________________________________________________________

function out = mysetstr(in)
tmp = find(in == 0);
tmp = min([min(tmp) length(in)]);
out = char(in(1:tmp));
return;
