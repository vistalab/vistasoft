function class=VMR2mrGrayClass(VMRfile, classFileName);
% function class=VMR2mrGrayClass(VMRfile);
% Function to convert between Brainvoyager VMR file format and mrGray class file.
% ARW 100300
% 040202: Note that BV flips L and R when it reads in anatomies.


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

if ~exist('classFileName','var')
    [f,p]=uiputfile('*.class');
end
classFileName = fullfile(p,f);
[y,x,z]=size(mainImg);

fprintf('\nData block is %d by %d by %d\n',y,x,z);

%comment = ['Converted from BrainVoyager VMR file ',VMRfile,' on ', datestr(now)];
class = writeClassFileFromRaw(mainImg, classFileName, [0,0; 240,16; 235,16]);
   
% path = writeVolAnatShortHeader(mainImg, mmPerPix);