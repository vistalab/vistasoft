function d = fmris_read_analyze(file,Z,T);
%
% Read in 1 4D or >1 3D Analyze format Image Volumes
%
% Usage
%
% d=Read_Analyze(file);
% Reads in all image data and attributes into the structure d.
%
% d=Read_Analyze(file,Z,T);
% Reads in chosen planes and frames and attributes into the structure d.
% Z and T are vectors e.g. Z=1:31;T=1:12; or Z=[24 26];T=[1 3 5];
%
% (c) Roger Gunn & John Aston  
%
% HISTORY:
% 2004.02.15 Bob Dougherty (RFD): fixed minor bug- d.file_name gets
% clobbered, so we use 'file' instead.
% Get machine format on which the file was written:
machineformat = getmachineformat(file);
if ~isempty(machineformat)
   % Read Header Information
   d = Read_Analyze_Hdr(file,machineformat);
   
   % try to get file precision if it is unknown:
   if strcmp(d.precision,'Unknown')
      d.precision=getprecision(deblank(file),machineformat,d.dim,d.global);
   end
   % Read Image Data
   if ~isempty(d) & ~strcmp(d.precision,'Unknown') 
      
      if nargin==1 | strcmp(d.precision,'uint1') 
         
         % Read in Whole Analyze Volume
         fid = fopen(file,'r',machineformat);
         if fid > -1
            d.data=d.scale*reshape(fread(fid,prod(d.dim),d.precision),d.dim(1),d.dim(2),d.dim(3),d.dim(4));
            fclose(fid);
         else
            errordlg('Check Image File: Existence, Permissions ?','Read Error'); 
         end;
         
         if nargin==3
            if all(Z>0)&all(Z<=d.dim(3))&all(T>0)&all(T<=d.dim(4))
               d.data=d.data(:,:,Z,T);
               d.Z=Z;
               d.T=T;
            else
               errordlg('Incompatible Matrix Identifiers !','Read Error');  
            end
         end
         
      elseif nargin==3
         % Read in Chosen Planes and Frames
         if (T(1)~=0)|(Z(1)~=0)
            
            if all(Z>0)&all(Z<=d.dim(3))&all(T>0)&all(T<=d.dim(4))
               
               fid = fopen(d.file_name,'r',machineformat);
               if fid > -1
                  d.data=zeros(d.dim(1),d.dim(2),length(Z),length(T));
                  for t=1:length(T)
                     for z=1:length(Z)
                        status=fseek(fid,d.hdr.byte*((T(t)-1)*prod(d.dim(1:3))+(Z(z)-1)*prod(d.dim(1:2))),'bof');
                        d.data(:,:,z,t)=d.scale*fread(fid,[d.dim(1) d.dim(2)],d.precision);
                     end
                  end
                  d.Z=Z;
                  d.T=T;
                  fclose(fid);
               else
                  errordlg('Check Image File: Existence, Permissions ?','Read Error'); 
               end;
               
            else
               errordlg('Incompatible Matrix Identifiers !','Read Error'); 
            end;
            
         end;
      else
         errordlg('Unusual Number of Arguments','Read Error');
      end;
   else
      if strcmp(d.precision,'Unknown');
         errordlg('Unknown Data Type (Precision?)','Read Error');
      end
   end;
else
   errordlg('Unknown Machine Format','Read Error'); 
end
% if there is no slice thickness, set it to 6mm:
if d.vox(3)==0
   d.vox(3)=6;
end
d.file_name = file;
return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function machineformat=getmachineformat(file);
% Get machine format by reading the d.hdr.dim(1) attribute and 
% making sure it is 1, 2, 3 or 4. 
machineformat=[];
for mf='nlbdgcas'
   fid = fopen([file(1:(length(file)-3)) 'hdr'],'r',mf);
   if fid > -1
      fseek(fid,40,'bof');
      if any(fread(fid,1,'int16')==1:4)
         machineformat=mf;
         fclose(fid);
         break
      else
         fclose(fid);
      end
   else
      errordlg('Check Header File: Existence, Permissions ?','Read Error'); 
      break
   end
end
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function precision=getprecision(file,machineformat,dim,range);
% Get precision by reading a value from the middle of the .img file and 
% making sure it is within the global attribute
precisions=['int8   '   
        'int16  '  
        'int32  '  
        'int64  '   
        'uint8  '   
        'uint16 '  
        'uint32 '  
        'uint64 ' 
        'single ' 
        'float32' 
        'double ' 
        'float64' ];
nbytes=[1 2 4 8 1 2 4 8 4 4 8 8];
middle_vol=dim(1)*dim(2)*floor(dim(3)/2)+dim(1)*round(dim(2)/2)+round(dim(1)/2);
h=dir(file);
n=ceil(h.bytes/prod(dim));
fid = fopen(file,'r',machineformat);
if fid > -1
   for i=1:size(precisions,1)
      if nbytes(i)==n
         status=fseek(fid,middle_vol*n,'bof');
         if status==0
            precision=deblank(precisions(i,:));
            x=fread(fid,10,precision);
            if all(range(1)<=x) & all(x<=range(2))
               return
            end
         end
      end
   end
end
errordlg('Check Header File: Existence, Permissions ?','Read Error'); 
precision='Unknown';
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d=Read_Analyze_Hdr(file,machineformat);
% Read Analyze Header information into the structure d
% Adapted from John Ashburners spm_hread.m
fid  = fopen([file(1:(length(file)-3)) 'hdr'],'r',machineformat);
if fid > -1
   
   % read (struct) header_key
   %---------------------------------------------------------------------------
   fseek(fid,0,'bof');
   
   d.hdr.sizeof_hdr 		= fread(fid,1,'int32');
   d.hdr.data_type  		= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.db_name    		= deblank(setstr(fread(fid,18,'char'))');
   d.hdr.extents    		= fread(fid,1,'int32');
   d.hdr.session_error   	= fread(fid,1,'int16');
   d.hdr.regular    		= deblank(setstr(fread(fid,1,'char'))');
   d.hdr.hkey_un0    		= deblank(setstr(fread(fid,1,'char'))');
   
   
   
   % read (struct) image_dimension
   %---------------------------------------------------------------------------
   fseek(fid,40,'bof');
   
   d.hdr.dim    			= fread(fid,8,'int16');
   d.hdr.vox_units    		= deblank(setstr(fread(fid,4,'char'))');
   d.hdr.cal_units    		= deblank(setstr(fread(fid,8,'char'))');
   d.hdr.unused1			= fread(fid,1,'int16');
   d.hdr.datatype			= fread(fid,1,'int16');
   d.hdr.bitpix				= fread(fid,1,'int16');
   d.hdr.dim_un0			= fread(fid,1,'int16');
   d.hdr.pixdim				= fread(fid,8,'float');
   d.hdr.vox_offset			= fread(fid,1,'float');
   d.hdr.funused1			= fread(fid,1,'float');
   d.hdr.funused2			= fread(fid,1,'float');
   d.hdr.funused3			= fread(fid,1,'float');
   d.hdr.cal_max			= fread(fid,1,'float');
   d.hdr.cal_min			= fread(fid,1,'float');
   d.hdr.compressed			= fread(fid,1,'int32');
   d.hdr.verified			= fread(fid,1,'int32');
   d.hdr.glmax				= fread(fid,1,'int32');
   d.hdr.glmin				= fread(fid,1,'int32');
   
   % read (struct) data_history
   %---------------------------------------------------------------------------
   fseek(fid,148,'bof');
   
   d.hdr.descrip			= deblank(setstr(fread(fid,80,'char'))');
   d.hdr.aux_file			= deblank(setstr(fread(fid,24,'char'))');
   d.hdr.orient				= fread(fid,1,'char');
   d.hdr.origin				= fread(fid,5,'uint16');
   d.hdr.generated			= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.scannum			= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.patient_id			= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.exp_date			= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.exp_time			= deblank(setstr(fread(fid,10,'char'))');
   d.hdr.hist_un0			= deblank(setstr(fread(fid,3,'char'))');
   d.hdr.views				= fread(fid,1,'int32');
   d.hdr.vols_added			= fread(fid,1,'int32');
   d.hdr.start_field		= fread(fid,1,'int32');
   d.hdr.field_skip			= fread(fid,1,'int32');
   d.hdr.omax				= fread(fid,1,'int32');
   d.hdr.omin				= fread(fid,1,'int32');
   d.hdr.smax				= fread(fid,1,'int32');
   d.hdr.smin				= fread(fid,1,'int32');
   
   fclose(fid);
   
   % Put important information in main structure
   %---------------------------------------------------------------------------
   
   d.dim    	  			= d.hdr.dim(2:5)';
   vox 						= d.hdr.pixdim(2:5)';
   if 	vox(4)==0 
      vox(4)=[];
   end
   d.vox       				= vox;
   d.vox_units       		= d.hdr.vox_units;
   d.vox_offset	    		= d.hdr.vox_offset;
   scale     				= d.hdr.funused1;
   d.scale     			  	= ~scale + scale;
   d.global					= [d.hdr.glmin d.hdr.glmax];
   d.calib					= [d.hdr.cal_min d.hdr.cal_max];
   d.calib_units			= d.hdr.cal_units;
   d.origin    				= d.hdr.origin(1:3)';
   d.descrip   				= d.hdr.descrip(1:max(find(d.hdr.descrip)));
   
   switch d.hdr.datatype
   case 1
      d.precision 	= 'uint1';
      d.hdr.byte 	= 0;
   case 2
      d.precision 	= 'uint8';
      d.hdr.byte 	= 1;
   case 4
      d.precision 	= 'int16';
      d.hdr.byte 	= 2;
   case 8
      d.precision 	= 'int32';
      d.hdr.byte 	= 4;
   case 16
      d.precision 	= 'float';
      d.hdr.byte 	= 4;
   case 64
      d.precision 	= 'double';
      d.hdr.byte 	= 8;
   otherwise
      d.precision 	= 'Unknown';
      d.hdr.byte 	= 0;
   end
   
else
   d=[];
   errordlg('Check Header File: Existence, Permissions ?','Read Error'); 
end
return
