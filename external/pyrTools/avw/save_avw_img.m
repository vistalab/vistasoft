function save_avw_img(img,fname,vtype);
%  SAVE_AVW_IMG(img,fname,vtype)
%
%  Save an array (img) as an analyse file (only the .img)
%   for either a 2D or 3D or 4D array (automatically determined)
%
%  vtype is a single character string: 'b' (unsigned) byte, 's' short,
%                                      'i' int, 'f' float, or 'd' double
%
%  See also: SAVE_AVW, SAVE_AVW_HDR, SAVE_AVW_COMPLEX,
%            READ_AVW, READ_AVW_HDR, READ_AVW_IMG, READ_AVW_COMPLEX
%

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
fnimg=strcat(fname,'.img');

fp=fopen(fnimg,'w');
dims = size(img);

dat = img;
dat = reshape(dat,prod(dims),1);

switch vtype
  case 'd'
    vtype2='double';
  case 'f'
    vtype2='float';
  case 'i'
    vtype2='int32';
  case 's'
    vtype2='short';
  case 'b'
    vtype2='uchar';
end;

fwrite(fp,dat,vtype2);
fclose(fp);

