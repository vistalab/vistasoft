function path=VMR2mrGrayNew(mmPerPix,VMRfile);
% function path=VMR2mrGrayNew(mmPerPix, VMRfile);
% Function to convert between Brainvoyager VMR file format and mrGray
% ARW 100300
% 040202: Note that BV flips L and R when it reads in anatomies.


if ~exist('mmPerPix','var')
   mmPerPix = [240/256 240/256 1.2];
   disp(['mmPerPix defaulting to [ ' num2str(mmPerPix,'%.4f ') ...
         	'].  I hope this is correct!']);
end

if ~exist('VMRfile','var')
    [VMRfile,VMRpath]=uigetfile('*.vmr');
end
VMRfile=[VMRpath,VMRfile];
disp(['Loading ',VMRfile]);

fid=fopen(VMRfile,'r');
header=fread(fid,3,'int16');
mainImg=fread(fid,'uchar');
fclose(fid);
mainImg=reshape(mainImg,[header(1),header(2),header(3)]);
disp('Flipping images...');

for thisIm=1:header(3)
   mainImg(:,:,thisIm)=rot90(fliplr(mainImg(:,:,thisIm)));
end
path = writeVolAnatShortHeader(mainImg, mmPerPix);