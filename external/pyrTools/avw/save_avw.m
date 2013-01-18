function save_avw(img,fname,vtype,vsize)
% SAVE_AVW(img,fname,vtype,vsize)
%
%  Create and save an analyse header (.hdr) and image (.img) file
%   for either a 2D or 3D or 4D array (automatically determined).
%  fname is the filename (must be inside single quotes)
%
%  vtype is 1 character: 'b'=unsigned byte, 's'=short, 'i'=int, 'f'=float
%                        'd'=double or 'c'=complex
%  vsize is a vector [x y z tr] containing the voxel sizes in mm and
%  the tr in seconds  (defaults: [1 1 1 3])
%
%  See also: READ_AVW
%

   if ((~isreal(img)) & (vtype~='c')),
     disp('WARNING:: Overwriting type - saving as complex');
     save_avw_complex(img,fname,vsize);
   else
     if (vtype=='c'),
       save_avw_complex(img,fname,vsize);
     else
       save_avw_hdr(img,fname,vtype,vsize);
       save_avw_img(img,fname,vtype);
     end
   end

