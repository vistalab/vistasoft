function [d]=fmris_write_analyze(d,Z,T);

% Write Analyze format Image Volumes
%
% Usage
%
% rpm_write_analyze(d,Z,T);
% 
% Writes image data and attributes from the structure d.
% The following fields are required from d. 
%
% d.file_name: 'sub09.img'
% d.data: [128x128x31 double]
% d.vox: [2.0900 2.0900 3.4200]
% d.vox_units: 'mm'
% d.vox_offset: 0
% d.calib_units: 'min^-1'
% d.origin: [0 0 0];
% d.descrip: 'Parametric Image - K1 (1)'
%
% All other information is generated automatically.
%
% (c) Roger Gunn & John Aston  

if isfield(d,'parent_file')
   d2=fmris_read_image(d.parent_file,0,0);
   d.vox=d2.vox;
   d.vox_units=d2.vox_units;
   d.calib_units='';
   d.origin=d2.origin;
   d.vox_offset=d2.vox_offset;
end
if ~isfield(d,'descrip')
   d.descrip='';
end
if ~isfield(d,'precision')
    d.precision='float';
end
file = d.file_name;

if length(size(d.data))<5&size(d.data,1)>1&size(d.data,2)>1&length(d.origin)<4
    
    d.calib = [1 1];  
    
    % Write Header
    if nargin==1
        [d]=Write_Analyze_Hdr(d);
    elseif nargin==3
        if (T(1)==1&Z(1)==1)
            [d]=Write_Analyze_Hdr(d);
        else
            d3 = fmris_read_image(file,0,0);
            d.hdr = d3.hdr;
        end      
    end
    
    if ~isstruct(d);
        return
    end
    % Write Image 
    if nargin==1
        if ~isempty(d)
            fid = fopen(file,'w','n');
            if fid > -1
%                 if(strcmp(d.precision,'float'))
%                     d.data = d.data./d.hdr.funused1;
%                 end
                for t=1:d.hdr.dim(5)
                    for z=1:d.hdr.dim(4)
                        fwrite(fid,d.data(:,:,z,t),d.precision);
                    end
                end
                fclose (fid);
            else
                errordlg('Cannot open file for writing  ','Write Error');d=[];return;
            end
        end
    elseif nargin==3    
        if T(1)~=1|Z(1)~=1
            if ~exist(file,'file')
                errordlg('Please write Plane 1 Frame 1 first','Write Error');return;
            end
        else
            fid=fopen(file,'w','n');fclose(fid);
        end
        fid = fopen(file,'r+','n');
        if fid > -1
            if T(1)==1&Z(1)==1
                plane=zeros(d.dim(1:2));
                for t=1:d.hdr.dim(5)
                    for z=1:d.hdr.dim(4)
                        fwrite(fid,plane,d.precision);
                    end
                end      
            end
            
            for t=1:length(T)
                for z=1:length(Z)
                    fseek(fid,4*d.dim(1)*d.dim(2)*((T(t)-1)*d.dim(3)+Z(z)-1),'bof');
                    if length(Z)~=1;
                        fwrite(fid,d.data(:,:,z,t),'float');
                    else
                        fwrite(fid,d.data(:,:,t),'float');
                    end
                end
            end
            
            fclose (fid);
            
        else
            errordlg('Cannot open file for writing  ','Write Error');d=[];return;
            
        end
    end
    
else
    errordlg('Incompatible data structure: Check dimension and Origin  ','Write Error'); 
end

return;



function [d]=Write_Analyze_Hdr(d);

% Write Analyze Header from the structure d
% Adapted from John Ashburners spm_hwrite.m

d.file_name_hdr=[d.file_name(1:(length(d.file_name)-3)) 'hdr'];
file=d.file_name_hdr;

fid   			= fopen(file,'w','n');
if fid > -1
    d.hdr.data_type 			= ['dsr      ' 0];
    d.hdr.db_name	  		= ['                 ' 0];
    if isfield(d,'dim')
        d.hdr.dim    			= [4 1 1 1 1 0 0 0];
        d.hdr.dim(2:(1+length(d.dim(find(d.dim)))))= d.dim(find(d.dim));
    else
        d.hdr.dim    			= [4 1 1 1 1 0 0 0];
        d.hdr.dim(2:(1+length(size(d.data))))   = size(d.data);
    end   
    
    d.hdr.pixdim 			= [4 0 0 0 0 0 0 0];
    d.hdr.pixdim(2:(1+length(d.vox))) = d.vox;
    d.hdr.vox_units			= [0 0 0 0];
    d.hdr.vox_units(1:min([3 length(d.vox_units)])) = d.vox_units(1:min([3 length(d.vox_units)]));
    d.hdr.vox_offset 		= d.vox_offset;
    d.hdr.calmin				= d.calib(1);
    d.hdr.calmax				= d.calib(2);
    switch d.precision
    case 'uint1'  % 1  bit
        d.hdr.datatype 		= 1;
        d.hdr.bitpix 			= 1;
        d.hdr.glmin			= 0;
        d.hdr.glmax 			= 1;
        d.hdr.funused1		= 1;   
    case 'uint8'  % 8  bit
        d.hdr.datatype 		= 2;
        d.hdr.bitpix 			= 8;
        d.hdr.glmin 			= 0;
        d.hdr.glmax 			= 255;
        d.hdr.funused1	= abs(d.hdr.calmin)/255;
        %errordlg('You should write a float image','8 Bit Write Error');d=[];return;
    case 'int16'  % 16 bit
        d.hdr.datatype 		= 4;
        d.hdr.bitpix  		= 16;
        d.hdr.funused1 		= 1;       
%         if abs(d.hdr.calmin)>abs(d.hdr.calmax)
%             d.hdr.funused1  	= abs(d.hdr.calmin)/(2^15-1);
%         else
%             d.hdr.funused1	= abs(d.hdr.calmax)/(2^15-1);
%         end
        d.hdr.glmin 			= round(d.hdr.funused1*d.hdr.calmin);
        d.hdr.glmax 			= round(d.hdr.funused1*d.hdr.calmin);
    case 'int32'  % 32 bit
        d.hdr.datatype 		= 8;
        d.hdr.bitpix  		= 32;
        d.hdr.funused1 		= 1;
%         if abs(d.hdr.calmin)>abs(d.hdr.calmax)
%             d.hdr.funused1  	= abs(d.hdr.calmin)/(2^31-1);
%         else
%             d.hdr.funused1	= abs(d.hdr.calmax)/(2^31-1);
%         end
        d.hdr.glmin 			= round(d.hdr.funused1*d.hdr.calmin);
        d.hdr.glmax 			= round(d.hdr.funused1*d.hdr.calmin);
    case 'float'  % float  (32 bit)
        d.hdr.datatype 		= 16;
        d.hdr.bitpix 	 		= 32;
        d.hdr.glmin 			= 0;
        d.hdr.glmax 			= 0;
        d.hdr.funused1 		= 1;
    case 'double' % double (64 bit) 
        d.hdr.datatype 		= 64;
        d.hdr.bitpix  		= 64;
        d.hdr.glmin 			= 0;
        d.hdr.glmax 			= 0;
        d.hdr.funused1 		= 1;
    otherwise
        errordlg('Unrecognised precision (d.type)','Write Error');d=[];return;
    end
    d.hdr.descrip 			= zeros(1,80);d.hdr.descrip(1:min([length(d.descrip) 79]))=d.descrip(1:min([length(d.descrip) 79]));
    d.hdr.aux_file        	= ['none                   ' 0];
    d.hdr.origin          	= [0 0 0 0 0];d.hdr.origin(1:length(d.origin))=d.origin;
    
    
    % write (struct) header_key
    %---------------------------------------------------------------------------
    fseek(fid,0,'bof');
    
    fwrite(fid,348,					'int32');
    fwrite(fid,d.hdr.data_type,	'char' );
    fwrite(fid,d.hdr.db_name,		'char' );
    fwrite(fid,0,					'int32');
    fwrite(fid,0,					'int16');
    fwrite(fid,'r',					'char' );
    fwrite(fid,'0',					'char' );
    
    
    % write (struct) image_dimension
    %---------------------------------------------------------------------------
    fseek(fid,40,'bof');
    
    fwrite(fid,d.hdr.dim,			'int16');
    fwrite(fid,d.hdr.vox_units,	'char' );
    fwrite(fid,zeros(1,8),			'char' );
    fwrite(fid,0,					'int16');
    fwrite(fid,d.hdr.datatype,	'int16');
    fwrite(fid,d.hdr.bitpix,		'int16');
    fwrite(fid,0,					'int16');
    fwrite(fid,d.hdr.pixdim,		'float');
    fwrite(fid,d.hdr.vox_offset,	'float');
    fwrite(fid,d.hdr.funused1,	'float');
    fwrite(fid,0,					'float');
    fwrite(fid,0,					'float');
    fwrite(fid,d.hdr.calmax,		'float');
    fwrite(fid,d.hdr.calmin,		'float');
    fwrite(fid,0,					'int32');
    fwrite(fid,0,					'int32');
    fwrite(fid,d.hdr.glmax,		'int32');
    fwrite(fid,d.hdr.glmin,		'int32');
    
    % write (struct) data_history
    %---------------------------------------------------------------------------
    fwrite(fid,d.hdr.descrip,		'char');
    fwrite(fid,d.hdr.aux_file,   	'char');
    fwrite(fid,0,           		'char');
    fwrite(fid,d.hdr.origin,     'uint16');
    fwrite(fid,zeros(1,85), 		'char');
    
    s   = ftell(fid);
    fclose(fid);
else
    errordlg('Cannot open file for writing  ','Write Error');d=[];return;
end

return;
