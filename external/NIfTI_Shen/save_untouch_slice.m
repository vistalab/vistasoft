%  Save back to the back to the original image a portion of slices that
%  were loaded by "load_untouch_nii". You can process those slices matrix
%  in any way, as long as their dimension is not changed.
%
%  Usage: save_untouch_slice(slice, filename, ...
%		slice_idx, [img_idx], [dim5_idx], [dim6_idx], [dim7_idx])
%
%  Example:
%	nii = load_nii('avg152T1_LR_nifti.nii');
%	save_nii(nii, 'test.nii');
%	view_nii(nii);
%	nii = load_untouch_nii('test.nii','','','','','',[40 51:53]);
%	nii.img = ones(91,109,4)*122;
%	save_untouch_slice(nii.img, 'test.nii', [40 51:52]);
%	nii = load_nii('test.nii');
%	view_nii(nii);
%
%  - Jimmy Shen (jimmy@rotman-baycrest.on.ca)
%
function save_untouch_slice(slice, filename, slice_idx, img_idx, dim5_idx, dim6_idx, dim7_idx)

   if ~exist('filename','var') | ~exist('slice_idx','var')
      error('Usage: save_untouch_slice(slice, filename, slice_idx, [img_idx], [dim5_idx], [dim6_idx], [dim7_idx])');
   end

   if ~exist('img_idx','var') | isempty(img_idx)
      img_idx = [];
   end

   if ~exist('dim5_idx','var') | isempty(dim5_idx)
      dim5_idx = [];
   end

   if ~exist('dim6_idx','var') | isempty(dim6_idx)
      dim6_idx = [];
   end

   if ~exist('dim7_idx','var') | isempty(dim7_idx)
      dim7_idx = [];
   end

   %  Read the dataset header
   %
   [nii.hdr,nii.filetype,nii.fileprefix,nii.machine] = load_nii_hdr(filename);

   if nii.filetype == 0
      nii.hdr = load_untouch0_nii_hdr(nii.fileprefix,nii.machine);
   else
      nii.hdr = load_untouch_nii_hdr(nii.fileprefix,nii.machine,nii.filetype);
   end

   %  Save the dataset body
   %
   save_untouch_slice_img(slice,filename,nii.hdr,nii.filetype,nii.fileprefix, ...
	nii.machine,slice_idx,img_idx,dim5_idx,dim6_idx,dim7_idx);

   return					% save_untouch_slice


%--------------------------------------------------------------------------
function save_untouch_slice_img(slice,filename,hdr,filetype,fileprefix,machine,slice_idx,img_idx,dim5_idx,dim6_idx,dim7_idx)

   if ~exist('hdr','var') | ~exist('filetype','var') | ~exist('fileprefix','var') | ~exist('machine','var')
      error('Usage: save_untouch_slice_img(slice,filename,hdr,filetype,fileprefix,machine,slice_idx,[img_idx],[dim5_idx],[dim6_idx],[dim7_idx]);');
   end

   if ~exist('slice_idx','var') | isempty(slice_idx) | hdr.dime.dim(4)<1
      slice_idx = [];
   end

   if ~exist('img_idx','var') | isempty(img_idx) | hdr.dime.dim(5)<1
      img_idx = [];
   end

   if ~exist('dim5_idx','var') | isempty(dim5_idx) | hdr.dime.dim(6)<1
      dim5_idx = [];
   end

   if ~exist('dim6_idx','var') | isempty(dim6_idx) | hdr.dime.dim(7)<1
      dim6_idx = [];
   end

   if ~exist('dim7_idx','var') | isempty(dim7_idx) | hdr.dime.dim(8)<1
      dim7_idx = [];
   end

   %  check img_idx
   %
   if ~isempty(img_idx) & ~isnumeric(img_idx)
      error('"img_idx" should be a numerical array.');
   end

   if length(unique(img_idx)) ~= length(img_idx)
      error('Duplicate image index in "img_idx"');
   end

   if ~isempty(img_idx) & (min(img_idx) < 1 | max(img_idx) > hdr.dime.dim(5))
      max_range = hdr.dime.dim(5);

      if max_range == 1
         error(['"img_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"img_idx" should be an integer within the range of [' range '].']);
      end
   end

   %  check dim5_idx
   %
   if ~isempty(dim5_idx) & ~isnumeric(dim5_idx)
      error('"dim5_idx" should be a numerical array.');
   end

   if length(unique(dim5_idx)) ~= length(dim5_idx)
      error('Duplicate index in "dim5_idx"');
   end

   if ~isempty(dim5_idx) & (min(dim5_idx) < 1 | max(dim5_idx) > hdr.dime.dim(6))
      max_range = hdr.dime.dim(6);

      if max_range == 1
         error(['"dim5_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"dim5_idx" should be an integer within the range of [' range '].']);
      end
   end

   %  check dim6_idx
   %
   if ~isempty(dim6_idx) & ~isnumeric(dim6_idx)
      error('"dim6_idx" should be a numerical array.');
   end

   if length(unique(dim6_idx)) ~= length(dim6_idx)
      error('Duplicate index in "dim6_idx"');
   end

   if ~isempty(dim6_idx) & (min(dim6_idx) < 1 | max(dim6_idx) > hdr.dime.dim(7))
      max_range = hdr.dime.dim(7);

      if max_range == 1
         error(['"dim6_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"dim6_idx" should be an integer within the range of [' range '].']);
      end
   end

   %  check dim7_idx
   %
   if ~isempty(dim7_idx) & ~isnumeric(dim7_idx)
      error('"dim7_idx" should be a numerical array.');
   end

   if length(unique(dim7_idx)) ~= length(dim7_idx)
      error('Duplicate index in "dim7_idx"');
   end

   if ~isempty(dim7_idx) & (min(dim7_idx) < 1 | max(dim7_idx) > hdr.dime.dim(8))
      max_range = hdr.dime.dim(8);

      if max_range == 1
         error(['"dim7_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"dim7_idx" should be an integer within the range of [' range '].']);
      end
   end

   %  check slice_idx
   %
   if ~isempty(slice_idx) & ~isnumeric(slice_idx)
      error('"slice_idx" should be a numerical array.');
   end

   if length(unique(slice_idx)) ~= length(slice_idx)
      error('Duplicate index in "slice_idx"');
   end

   if ~isempty(slice_idx) & (min(slice_idx) < 1 | max(slice_idx) > hdr.dime.dim(4))
      max_range = hdr.dime.dim(4);

      if max_range == 1
         error(['"slice_idx" should be 1.']);
      else
         range = ['1 ' num2str(max_range)];
         error(['"slice_idx" should be an integer within the range of [' range '].']);
      end
   end

   write_image(slice,filename,hdr,filetype,fileprefix,machine,slice_idx,img_idx,dim5_idx,dim6_idx,dim7_idx);

   return					% save_untouch_slice_img


%---------------------------------------------------------------------
function write_image(slice,fn,hdr,filetype,fileprefix,machine,slice_idx,img_idx,dim5_idx,dim6_idx,dim7_idx)

   fid = fopen(fn,'r+',machine);

   if fid < 0,
      msg = sprintf('Cannot open file %s.',fn);
      error(msg);
   end

   %  Set bitpix according to datatype
   %
   %  /*Acceptable values for datatype are*/ 
   %
   %     0 None                     (Unknown bit per voxel) % DT_NONE, DT_UNKNOWN 
   %     1 Binary                         (ubit1, bitpix=1) % DT_BINARY 
   %     2 Unsigned char         (uchar or uint8, bitpix=8) % DT_UINT8, NIFTI_TYPE_UINT8 
   %     4 Signed short                  (int16, bitpix=16) % DT_INT16, NIFTI_TYPE_INT16 
   %     8 Signed integer                (int32, bitpix=32) % DT_INT32, NIFTI_TYPE_INT32 
   %    16 Floating point    (single or float32, bitpix=32) % DT_FLOAT32, NIFTI_TYPE_FLOAT32 
   %    32 Complex, 2 float32      (Use float32, bitpix=64) % DT_COMPLEX64, NIFTI_TYPE_COMPLEX64
   %    64 Double precision  (double or float64, bitpix=64) % DT_FLOAT64, NIFTI_TYPE_FLOAT64 
   %   128 uint8 RGB                 (Use uint8, bitpix=24) % DT_RGB24, NIFTI_TYPE_RGB24 
   %   256 Signed char            (schar or int8, bitpix=8) % DT_INT8, NIFTI_TYPE_INT8 
   %   511 Single RGB              (Use float32, bitpix=96) % DT_RGB96, NIFTI_TYPE_RGB96
   %   512 Unsigned short               (uint16, bitpix=16) % DT_UNINT16, NIFTI_TYPE_UNINT16 
   %   768 Unsigned integer             (uint32, bitpix=32) % DT_UNINT32, NIFTI_TYPE_UNINT32 
   %  1024 Signed long long              (int64, bitpix=64) % DT_INT64, NIFTI_TYPE_INT64
   %  1280 Unsigned long long           (uint64, bitpix=64) % DT_UINT64, NIFTI_TYPE_UINT64 
   %  1536 Long double, float128  (Unsupported, bitpix=128) % DT_FLOAT128, NIFTI_TYPE_FLOAT128 
   %  1792 Complex128, 2 float64  (Use float64, bitpix=128) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
   %  2048 Complex256, 2 float128 (Unsupported, bitpix=256) % DT_COMPLEX128, NIFTI_TYPE_COMPLEX128 
   %
   switch hdr.dime.datatype
   case   2,
      hdr.dime.bitpix = 8;  precision = 'uint8';
   case   4,
      hdr.dime.bitpix = 16; precision = 'int16';
   case   8,
      hdr.dime.bitpix = 32; precision = 'int32';
   case  16,
      hdr.dime.bitpix = 32; precision = 'float32';
   case  64,
      hdr.dime.bitpix = 64; precision = 'float64';
   case 128,
      hdr.dime.bitpix = 24; precision = 'uint8';
   case 256 
      hdr.dime.bitpix = 8;  precision = 'int8';
   case 511 
      hdr.dime.bitpix = 96; precision = 'float32';
   case 512 
      hdr.dime.bitpix = 16; precision = 'uint16';
   case 768 
      hdr.dime.bitpix = 32; precision = 'uint32';
   case 1024
      hdr.dime.bitpix = 64; precision = 'int64';
   case 1280
      hdr.dime.bitpix = 64; precision = 'uint64';
   otherwise
      error('This datatype is not supported'); 
   end

   hdr.dime.dim(find(hdr.dime.dim < 1)) = 1;

   %  move pointer to the start of image block
   %
   switch filetype
   case {0, 1}
      fseek(fid, 0, 'bof');
   case 2
      fseek(fid, hdr.dime.vox_offset, 'bof');
   end

   if hdr.dime.datatype == 1 | isequal(hdr.dime.dim(4:8),ones(1,5)) | ...
	(isempty(img_idx) & isempty(dim5_idx) & isempty(dim6_idx) & isempty(dim7_idx) & isempty(slice_idx))

      msg = [char(10) char(10) '   "save_untouch_slice" is used to save back to the original image a' char(10)];
      msg = [msg '   portion of slices that were loaded by "load_untouch_nii". You can' char(10)];
      msg = [msg '   process those slices matrix in any way, as long as their dimension' char(10)];
      msg = [msg '   is not changed.'];
      error(msg);
   else

      d1 = hdr.dime.dim(2);
      d2 = hdr.dime.dim(3);
      d3 = hdr.dime.dim(4);
      d4 = hdr.dime.dim(5);
      d5 = hdr.dime.dim(6);
      d6 = hdr.dime.dim(7);
      d7 = hdr.dime.dim(8);

      if isempty(slice_idx)
         slice_idx = 1:d3;
      end

      if isempty(img_idx)
         img_idx = 1:d4;
      end

      if isempty(dim5_idx)
         dim5_idx = 1:d5;
      end

      if isempty(dim6_idx)
         dim6_idx = 1:d6;
      end

      if isempty(dim7_idx)
         dim7_idx = 1:d7;
      end
      
      %ROMAN: begin
      roman = 1;
      if(roman)

         %  compute size of one slice
         %
         img_siz = prod(hdr.dime.dim(2:3));

         %  For complex float32 or complex float64, voxel values
         %  include [real, imag]
         %
         if hdr.dime.datatype == 32 | hdr.dime.datatype == 1792
            img_siz = img_siz * 2;
         end

         %MPH: For RGB24, voxel values include 3 separate color planes
         %
         if hdr.dime.datatype == 128 | hdr.dime.datatype == 511
            img_siz = img_siz * 3;
         end

      end; %if(roman)
      % ROMAN: end

      for i7=1:length(dim7_idx)
         for i6=1:length(dim6_idx)
            for i5=1:length(dim5_idx)
               for t=1:length(img_idx)
               for s=1:length(slice_idx)

                  %  Position is seeked in bytes. To convert dimension size
                  %  to byte storage size, hdr.dime.bitpix/8 will be
                  %  applied.
                  %
                  pos = sub2ind([d1 d2 d3 d4 d5 d6 d7], 1, 1, slice_idx(s), ...
			                    img_idx(t), dim5_idx(i5),dim6_idx(i6),dim7_idx(i7)) -1;
                  pos = pos * hdr.dime.bitpix/8;

                  % ROMAN: begin
                  if(roman)
                      % do nothing
                  else
                     img_siz = prod(hdr.dime.dim(2:3));

                     %  For complex float32 or complex float64, voxel values
                     %  include [real, imag]
                     %
                     if hdr.dime.datatype == 32 | hdr.dime.datatype == 1792
                        img_siz = img_siz * 2;
                     end

                     %MPH: For RGB24, voxel values include 3 separate color planes
                     %
                     if hdr.dime.datatype == 128 | hdr.dime.datatype == 511
                        img_siz = img_siz * 3;
                     end
                  end; % if (roman)
                  % ROMAN: end
         
                  if filetype == 2
                     fseek(fid, pos + hdr.dime.vox_offset, 'bof');
                  else
                     fseek(fid, pos, 'bof');
                  end

                  %  For each frame, fwrite will write precision of value
                  %  in img_siz times
                  %
                  fwrite(fid, slice(:,:,s,t,i5,i6,i7), sprintf('*%s',precision));
                  
               end
               end
            end
         end
      end
   end

   fclose(fid);

   return						% write_image

