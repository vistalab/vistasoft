function createSureFitRawData(volPixSize)
% createSureFitRawData([volPixSize])
%
% volPixSize is in mm/pixel (defaults to [240/256 240/256 1.2])
%
% Converts Ifile data into the row-major ordered (8-bit uchar) data
% format requried by SureFit. This script is essentiall the createVAnatomy script
% with the output format modified slightly (in saveSureFitAnat()  -- which was
% saveVAnat())
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

% crop the image cube
% (you can skip this if you want, and just do the crop in mrGray)
figure(1);image(squeeze(img2(round(end/2),:,:))./clip.*255);colormap(gray(256));axis image;
figure(2);image(squeeze(img2(:,round(end/2),:))./clip.*255);colormap(gray(256));axis image;
figure(3);image(squeeze(img2(:,:,round(end/2)))./clip.*255);colormap(gray(256));axis image;
img2 = img2(20:200,30:240,1:124);
figure(1);image(squeeze(img(round(end/2),:,:))./clip.*255);colormap(gray(256));axis image;
figure(2);image(squeeze(img(:,round(end/2),:))./clip.*255);colormap(gray(256));axis image;
figure(3);image(squeeze(img(:,:,round(end/2)))./clip.*255);colormap(gray(256));axis image;

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
