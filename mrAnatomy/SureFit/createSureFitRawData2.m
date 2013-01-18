function createSureFitRawData(volPixSize)
% createSureFitRawData([volPixSize])
%
% volPixSize is in mm/pixel (defaults to [240/256 240/256 1.2])
%
% Converts Ifile data into the row-major ordered (8-bit uchar) data
% format requried by SureFit. This script is essentially the 
% createVAnatomy script with the output format modified slightly 
%(in saveSureFitAnat()  -- which wa saveVAnat())
% 
% 00.01.20 RFD
%

if ~exist('volPixSize','var')
   volPixSize = [240/256 240/256 1.2];
   disp(['volPixSize defaulting to [ ' num2str(volPixSize,'%.4f ') ...
         	'].  I hope this is correct!']);
end

volume_pix_size = 1./volPixSize;

[fname, path] = uigetfile('*.*', 'Select one of the I-files...');

% load ifiles
%
disp('Loading I-files...');
img = makeCubeIfiles([path 'I'], 256, [1:124]);

disp('Finding optimal clip values...');
figure(99);
hist(img(:),100);
lowerClip = 0;
upperClip = 500;
answer = inputdlg({'lower clip value: ','upper clip value: '}, ...
   'Set intensity clip values', 1, ...
   {num2str(lowerClip),num2str(upperClip)}, 'on');
if ~isempty(answer)
	lowerClip = str2num(answer{1});
	upperClip = str2num(answer{2});
end
disp(['intensity clip values are: ' num2str(lowerClip) ', ' num2str(upperClip)]);

% Scale image values to be 0-255
% (if intensityClip <= 1, my scaleImage routine will clip the highest 'intensityClip' 
% proportion of values, or, if intensityClip > 1, it clips it to the image value 
% specified by intensityClip.
%
% I haven't been fully satisfied by just automatically clipping off the top,
% say 2% of intensities (this is what mrInitRet currently does to the inplanes).
% So, lately I've been looking at the histogram and picking intensityClip
% by hand, then viewing the images to see how well it worked.
disp('Clipping intensities...');
img(img<lowerClip) = lowerClip;
img(img>upperClip) = upperClip;
img = img-lowerClip;

disp('Scaling to 0-255...');
img = round(img./upperClip*255);
disp('Original orientation:');
figure(99);
subplot(2,2,1);
image(squeeze(img(round(end/2),:,:)));colormap(gray(256));axis image;axis off;
subplot(2,2,2);
image(squeeze(img(:,round(end/2),:)));colormap(gray(256));axis image;axis off;
subplot(2,2,4);
image(squeeze(img(:,:,round(end/2))));colormap(gray(256));axis image;axis off;


% Reslice the data so that all voxels are cubic.
% The image currently has a field of view (fov) of 240mm in 256 voxels on the x and y axes
% and a fov of 148.800mm in 124 voxels on the z axis.

reslicedImg = resliceVoxels(img, 240, 240, 148.800);


% Reorient the data into the orientation expected by SureFit
% Basically, the data needs to be rotated 90 degrees around the anterior-posterior axis of the brain
% The image data is no 159x256x256

disp('Reorienting data...');

rotImg= zeros(planes,rows,cols);
for index=1:rows
   rotImg(:,index,:) = rot90(squeeze(reslicedImg(:,index,:)),3);
end

disp(['Volume dimensions are now:' int2str(size(rotImg))]);

disp('The reoriented data:');
figure(100);
subplot(2,2,1);
image(squeeze(rotImg(round(end/2),:,:)));colormap(gray(256));axis image;axis off;
subplot(2,2,2);
image(squeeze(rotImg(:,round(end/2),:)));colormap(gray(256));axis image;axis off;
subplot(2,2,4);
image(squeeze(rotImg(:,:,round(end/2))));colormap(gray(256));axis image;axis off;

% Save SureFitAnatomy
%
disp('Saving data in SureFit raw Format...');
path = saveSureFitAnat(rotImg);
save([path 'UnfoldParams'], 'volume_pix_size', 'lowerClip', 'upperClip');
disp(['SureFit raw data format saved to ' path]);
disp(['You should now run "python SUREFit/bin/Raw2Minc "' path size(rotImg)]);

return;


function path = saveSureFitAnat(imgCube, fileName)
% path = saveSureFitAnat(imgCube, [fileName])
% imgCube is a [rows x cols x planes] image array
% It must already be scaled to 0-255!
%
% fileName specifies the output file location (full path!)
% If omitted, then a save-file dialog box appears.
% 
% The path to where the anatomy ends up is returned, in
% case you care.
% 
%
% See Also: writeVolume, which does the same thing, but takes 
% the input data in a different format.
%
% RFD

if ~exist('fileName', 'var')
   fileName = '';
end

% open file for writing (little-endian mode)
if isempty(fileName)
	[fname, path] = uiputfile('sureFitRawData.dat', 'Save SureFit raw data file...');
   fileName = [path fname];
else
   path = fileName;
end

vFile = fopen(fileName,'w','l');
if vFile<1
   while vFile<1;
   disp('Couldn''t open that file- please try saving it somewhere else.');
	[fname, path] = uiputfile('sureFitRawData.dat', 'Save SureFit raw data file...');
   fileName = [path fname];
   vFile = fopen(fileName,'w','l');
	end
end
   
% SureFit's Raw2Minc doesn't want any header, so nothing is written before the image data.


% Write data
count = fwrite(vFile, imgCube, 'uchar');
fclose(vFile);

return;


function  img = makeCubeIfiles(baseFileName, imDim, imList)
% img = makeCubeIfiles(baseFileName, imDim, imList)
%
% Reads in reconstructed Pfile images and compiles
% them into an image cube.  
%
% see also makeMontageIfiles

header = 0;
if strcmp(computer,'PCWIN')
	byteFlag = 'b';
else
   byteFlag = 'n';
end

if length(imDim) == 1
   r = imDim;
   c = imDim;
else
   r = imDim(1);
   c = imDim(2);
end

nImages = length(imList);
img = zeros(r,c,nImages);
count = 0;
for ii = imList
  count = count+1;
  fileName = sprintf('%s.%03d', baseFileName, ii);
  tempImg = readMRImage(fileName, header, [r c], byteFlag);
  img(:,:,count) = tempImg;
end

return;


function [img,header] = readMRImage(filename,header,imageSize,byteFlag)
%[img,header] = readMRImage(filename,[header],[imageSize],byteFlag)
%
%	filename is a string
%	imageSize is a vector of x and y sizes
%       header is a flag:
%	  if header = 1 then it uses the new header size of 7904
%	  if header = 2 then it uses the older header size of 7900
%         if imageSize is not given, readMRImage assumes that the
%         image is square with dimensions a power of two.  
%         if header = 0 or is not given readMRImage assumes that
%         Any extra data beyond imageSize is header material.

%4/10/98  gmb    Wrote it from myRead
%9/18/98  rmk    Added byteFlag which is a string passed to fopen to
%                control the byte-reading convention.  To read hp
%                format on a pc use byteFlag='b'

if ~exist('header','var')
  header = 0;
end

if ~exist('byteFlag','var')
  byteFlag='n';
end

% check to see if running on a pc:
if (strcmp(computer,'LNX86'))
  pc=1;
else
  pc=0;
end

%Uncompress file if <filename>.gz is found
if length(filename>3)
  if strcmp(filename(length(filename)-2:length(filename)),'.gz')
    filename = filename(1:length(filename)-3);
    uncompressFlag = 1;
    disp (['Uncompressing ',filename,' ...']);
    unix(['gunzip ',filename]);
  else
    uncompressFlag = 0;
  end
end

fid = fopen(filename,'r',byteFlag);

if fid == -1
  disp(sprintf('Could not open file %s',filename));
  img = [];
  header = 0;
  return
end
%strip off header
switch header
  case  0
    %deal with this later
  case  1 				%There is a header
    fseek(fid,7904,'bof');%Move start 7904 bytes from start of file
  case 2
    fseek(fid,7900,'bof');%Move start 7904 bytes from start of file
  otherwise
    fseek(fid,header,'bof');%Move start <header> bytes from start of file
end

%read in the rest of the file
img = fread(fid,'ushort');

%if imageSize not given, assume that it is the nearest power of 2 
if ~exist('imageSize','var') 	
  imageSize  = repmat(2^floor(log2(sqrt(length(img)))),1,2);
end                            

%if header is not given, estimate it from the difference
%between the image size and the length of img.

if ~header
  %crop off header
  header = (length(img)-prod(imageSize))*2;  
  img = img(header/2+1:length(img));
end

if prod(prod(imageSize) ~= length(img))
  disp(['*** Error in readMRImage:  imageSize does not match loaded image ''',filename,'''.']);
  img = [];
end

img(find(img>32767)) = zeros(size(find(img>32767)));
img = reshape(img,imageSize(1),imageSize(2))';

fclose(fid);

%Re-compress the file
if uncompressFlag
  disp (['Compressing   ',filename,' ...']);
  unix(['gzip ',filename]);
end


function reslicedImg = resliceVoxles(imgCubeData, rowSpan, colSpan, planeSpan)
% reslicedImg = resliceVoxles(imgCubeData, nRows, nCols, nPlanes, rowSpan, colSpan, planeSpan)
% Generalized function to reslice the voxels in a cubic array of image data so that voxels
% have are cubic in the physical space.
%
% Each entry of the matrix corresponds to one voxel in the image data.
% rowSpan, colSpan, and PlaneSpan refer to the linear distance spanned (in anatomical space) by each
% of the dimensions in the image data. For example if the image data had a field of view of 240mm in the
% x and y dimensions and a f.o.v. of 148mm in the z dimension, then
%  rowSpan = colSpan = 240
%  planeSpan = 148
% 
% resliceVoxels() returns a 3D matrix of voxel values.

error(nargchk(4,4,nargin));

disp('Reslicing image to cubic voxels...');

[nRows,nCols,nPlanes] = size(imgCubeData);


disp('Determining voxel dimensions...');

mmPerVoxelInX = colSpan / nCols;
disp([num2str(mmPerVoxelInX) 'mm per voxel in the x axis.']);

mmPerVoxelInY = rowSpan / nRows;
disp([num2str(mmPerVoxelInX) 'mm per voxel in the y axis.']);

mmPerVoxelInZ = planeSpan / nPlanes;
disp([num2str(mmPerVoxelInZ) 'mm per voxel in the z axis.']);

%%
% Compute the target cubic dimension by finding the smallest dimension

targetDimension = min([mmPerVoxelInX mmPerVoxelInY mmPerVoxelInZ]);
disp(['All voxels will be resliced to be cubic, ' num2str(targetDimension) 'mm per voxel.']);

% Compute number of slices in each dimension (rounded to the nearest integer).
numResampledSlicesX = round(colSpan / targetDimension);
numResampledSlicesY = round(rowSpan / targetDimension);
numResampledSlicesZ = round(planeSpan / targetDimension);


% Reslice the image. We do this in one step using inter3:

disp(['Resampling the x axis to ' int2str(numResampledSlicesX) ' slices...']);
disp(['Resampling the y axis to ' int2str(numResampledSlicesY) ' slices...']);
disp(['Resampling the z axis to ' int2str(numResampledSlicesZ) ' slices...']);

reslicedImg = zeros(numResampledSlicesX, numResampledSlicesY, numResampledSlicesZ);
reslicedImg = interp3(imgCubeData, linspace(1,nCols,numResampledSlicesX),linspace(1,nRows,numResampledSlicesY)',linspace(1,nPlanes,numResampledSlicesZ)');

disp(['Volume dimensions are now: ' int2str(size(reslicedImg))]);

return;