function [img,dims,scales,bpp,endian] = read_avw(fname)
% [img, dims,scales,bpp,endian] = READ_AVW(fname)
%
%  Read in an analyse file into either a 3D or 4D
%  array (depending on the header information)
%  fname is the filename (must be inside single quotes)
%  Note: automatically detects - unsigned char, short, long, float
%         double and complex formats
%  Extracts the 4 dimensions (dims),
%  4 scales (scales) and bytes per pixel (bpp) for voxels
%  contained in the Analyse header file (fname)
%  Also returns endian = 'l' for little-endian or 'b' for big-endian
%
%  See also: SAVE_AVW

  [dims,scales,bpp,endian,datatype]= read_avw_hdr(fname);
  if (datatype==32),
    % complex type
    img=read_avw_complex(fname);
  else
    img=read_avw_img(fname);
  end

