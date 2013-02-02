function write_mrtrix (image, filename)

% function: read_mrtrix (image, filename)
%
% write the data contained in the structure 'image' in the MRtrix 
% format image 'filename' (i.e. files with the extension '.mif' or '.mih').
%
% 'image' is either a N-dimensional array (N <= 16), or a structure containing
% the following fields:
%    image.data:       a N-dimensional array (N <= 16)
%    image.vox:        N-vector of voxel sizes (in mm) (default: { 2 }) [optional]
%    image.comments:   a cell array of strings [optional]
%    image.datatype:   the datatype specifier (default: float32) [optional]
%    image.transform:  a 4x4 matrix [optional]
%    image.DW_scheme:  a NDWx4 matrix of gradient directions [optional]


fid = fopen (filename, 'w');
fprintf (fid, 'mrtrix image\ndim: ');

if isstruct(image)
  dim = size(image.data);
else
  dim = size(image);
end
fprintf (fid, '%d', dim(1));
fprintf (fid, ',%d', dim(2:end));

fprintf (fid, '\nvox: ');
if isstruct (image) && isfield (image, 'vox')
  fprintf (fid, '%f', image.vox(1));
  fprintf (fid, ',%f', image.vox(2:end)); 
else
  fprintf(fid, '2');
  fprintf(fid, ',%d', 2*ones(1,size(dim,2)-1));
end

fprintf (fid, '\nlayout: +0');
fprintf (fid, ',+%d', 1:(size(dim,2)-1));

[computerType, maxSize, endian] = computer;
if isstruct (image) && isfield (image, 'datatype')
  datatype = lower(image.datatype);
  byteorder = datatype(end-1:end);

  if strcmp (byteorder, 'le')
    precision = datatype(1:end-2);
    byteorder = 'l';
  elseif strcmp(byteorder, 'be')
    precision = datatype(1:end-2);
    byteorder = 'b';
  else 
    if strcmp(datatype, 'bit')
      precision = 'bit1';
      byteorder = 'n';
    elseif strcmp (datatype, 'int8') || strcmp (datatype, 'uint8')
      precision = datatype;
      byteorder = 'n';
      if endian == 'L'
        datatype(end+1:end+3) = 'le';
      else
        datatype(end+1:end+3) = 'be';
      end 
    end
  end
else
  if endian == 'L'
    datatype = 'float32le';
  else 
    datatype = 'float32be';
  end 
  precision = 'float32';
  byteorder = 'n';
end
fprintf (fid, [ '\ndatatype: ' datatype ]);

if isstruct (image) && isfield (image, 'comments')
  fprintf (fid, '\ncomments: %s', image.comments)
end

if isstruct (image) && isfield (image, 'transform')
  fprintf (fid, '\ntransform: %d', image.transform(1,1))
  fprintf (fid, ',%d', image.transform(1,2:4))
  fprintf (fid, '\ntransform: %d', image.transform(2,1))
  fprintf (fid, ',%d', image.transform(2,2:4))
  fprintf (fid, '\ntransform: %d', image.transform(3,1))
  fprintf (fid, ',%d', image.transform(3,2:4))
end

if isstruct (image) && isfield (image, 'DW_scheme')
  for i=1:size(image.DW_scheme,1)
    fprintf (fid, '\nDW_scheme: %d', image.DW_scheme(i,1))
    fprintf (fid, ',%d', image.DW_scheme(i,2:4))
  end
end

if filename(end-3:end) == '.mif'
  datafile = filename;
  dataoffset = ftell (fid) + 16;
  fprintf (fid, '\nfile: . %d\nEND\n', dataoffset);
elseif filename(end-3:end) == '.mih'
  datafile = [ filename(end-3:end) '.dat' ];
  dataoffset = 0;
  fprintf (fid, '\nfile: %s %d\nEND\n', datafile, dataoffset);
else 
  disp ('unknown file suffix - aborting')
  return
end

fclose(fid);

fid = fopen (datafile, 'a', byteorder);
fseek (fid, dataoffset, -1);
ftell (fid);

if isstruct(image)
  fwrite (fid, image.data, precision);
else
  fwrite (fid, image, precision);
end
fclose (fid);

