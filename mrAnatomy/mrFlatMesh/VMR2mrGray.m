function path=VMR2mrGray(VMRfile,mmPerPix);
% function path=VMR2mrGray(VMRfile,mmPerPix);
% Function to convert between Brainvoyager VMR file format and mrGray
% Last edited : $Date: 2007/07/05 19:51:58 $
% ARW 100300
if ~exist('mmPerPix','var')
   mmPerPix = [240/256 240/256 1.2];
   disp(['mmPerPix defaulting to [ ' num2str(mmPerPix,'%.4f ') ...
         	'].  I hope this is correct!']);
end

fid=fopen(VMRfile,'r');
header=fread(fid,3,'int16');
mainImg=fread(fid,'uchar');
fclose(fid);
mainImg=reshape(mainImg,[header(1),header(2),header(3)]);
disp('Flipping images...');

for thisIm=1:header(3)
   mainImg(:,:,thisIm)=rot90(fliplr(mainImg(:,:,thisIm)));
end

path = writeVolAnat(mainImg, mmPerPix);