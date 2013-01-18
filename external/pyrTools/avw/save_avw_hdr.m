function save_avw_hdr(img,fname,vtype,vsize)
% SAVE_AVW_HDR(img,fname,vtype,vsize)
%
%  Create and save an analyse header file
%   for either a 2D or 3D or 4D array (automatically determined).
%
%  vtype is 1 character: 'b' unsigned byte, 's' short, 'i' int,
%                        'f' float, 'd' double
%  vsize is a vector [x y z tr] containing the voxel sizes in mm and
%  the tr in seconds  (defaults: [1 1 1 3])
%
%  See also: SAVE_AVW, SAVE_AVW_IMG, READ_AVW, READ_AVW_HDR, READ_AVW_IMG
%            SAVE_AVW_COMPLEX

% swap first and second argument in case save_avw_img convention is
% used
check=length(size(fname));
if(check~=2)
   tmp=img;
   img=fname;
   fname=tmp;
end

% remove extension if it exists
if ( (length(findstr(fname,'.hdr'))>0) | ...
        (length(findstr(fname,'.img')>0)) ),
  fname=fname(1:(length(fname)-4));
end

% remove headerfile
fname2=strcat(fname,'.hdr');
tmpstr1=sprintf('!touch %s', fname2);
tmpstr2=sprintf('!rm %s', fname2);

eval(tmpstr1);
eval(tmpstr2);

% establish dynamic range
imgmax=ceil(max(max(max(max(img)))));
imgmin=floor(min(min(min(min(img)))));

% create file to use as input into header program
dims = [size(img) 1 1];

if(nargin==2)
  vtype='s';
  vsize=[1 1 1 3];
elseif(nargin==3)
  tmp=size(vtype);
  if(tmp(2)==1)
     vsize=[1 1 1 3];
  else
     vsize=vtype;
     if size(vsize,2)==3
        vsize=[vsize 3];
     end;
     vtype='s';
  end
else
  tmp=size(vtype);
  if(tmp(2)==3)
     tmp2=vtype;
     vtype=vsize;
     vsize=tmp2;
  end
end

if (length(vsize)<3),
  vsize(3)=1;
end
if (length(vsize)<4),
  vsize(4)=3;
end

dtype=0;
if (vtype=='b'),
  dtype=2;
end
if (vtype=='s'),
  dtype=4;
end
if (vtype=='i'),
  dtype=8;
end
if (vtype=='f'),
  dtype=16;
end
if (vtype=='d'),
  dtype=64;
end


% call avwcreatehd program

tmp=sprintf('! /usr/local/fsl/bin/avwcreatehd %d %d %d %d %6.4f %6.4f %6.4f %6.4f 0 0 0 %d %s \n',dims(1),dims(2),dims(3),dims(4),vsize(1),vsize(2),vsize(3),vsize(4),dtype,fname);
eval(tmp);
disp(' ');

