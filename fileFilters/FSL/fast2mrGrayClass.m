function [V,mrGrayClassFileName]=fast2mrGrayClass(analHeaderFileName,outFileName)
% Convert Fast segmentation (FSL) to mrGray class file
%
% function [V,mrGrayClassFileName]=fast2mrGrayClass(analHeaderFileName,outFileName);
%
% Takes the resulting Analyze file from a Fast segmentation and saves it out
% as a mrGray .class file.  Fast's gray matter is thrown away, but white matter
% and CSF are kept. 
% This function is based on analyze2mrGrayClass and writeClassFile.
% writeClassFile appeared to have some problems, but if they are fixed
% then this function may become unnecessary.  
% Uses the SPM99 spm_vol command to parse the header. Uses misc. VISTA lab routines (see e.g. writeClassFile) to write the volume.
% ISS 071902

% Read the header
V=spm_vol(analHeaderFileName);

% Now read in the image data
fid=fopen(V.fname,'rb');
if (~fid)
    error (['Could not read header file: ',analHeaderFileName]);
end
imLen=prod([V.dim(3),V.dim(2),V.dim(1)]);

im=uint8(fread(fid,imLen,'uint8'));
fclose(fid);
imLen=length(im);

if(imLen~=prod(V.dim(1:3)))
    error('Wrong data size for 8-bit. Only 8 bit class files allowed');

end

im=reshape(im,V.dim(1:3));
mmPerVox=diag(V.mat(1:3,1:3));
mmPerVox=mmPerVox;



% Need to rearrange the image. Analyze data run with sag and axial directions flipped. Also u%pside down in mrGray...

newimg=zeros(V.dim(3),V.dim(2),V.dim(1));

for thisIm=1:(V.dim(2))
  newimg(:,end-(thisIm-1),:)=flipud(squeeze(im(:,thisIm,:))');
end


% Swap rows and columns
[y,x,z]=size(newimg);
tmp = zeros(x,y,z);
for ii=1:z
   tmp(:,:,ii) = newimg(:,:,ii)';
end
newimg = tmp;



    voiInfo.xMin=0;
    voiInfo.yMin=0;
    voiInfo.zMin=0;
    voiInfo.xMax=V.dim(3)-1;
    voiInfo.yMax=V.dim(2)-1;
    voiInfo.zMax=V.dim(1)-1;

    voiInfo.xSize=V.dim(3);
    voiInfo.ySize=V.dim(2);
    voiInfo.zSize=V.dim(1);
    disp(voiInfo);

   
newimg(newimg==2)=0; 
newimg(newimg==3)=16; 
newimg(newimg==1)=48; 

% Need to write out a class header...
% Open the file
% 
fp = fopen(outFileName,'w');
mrGrayClassFileName = fp;
% Read header information
% 
fprintf(fp, 'version=%d\n',2);
fprintf(fp, 'minor=%d\n',1);

fprintf(fp, 'voi_xmin=%d\n',voiInfo.xMin);
fprintf(fp, 'voi_xmax=%d\n',voiInfo.xMax);
fprintf(fp, 'voi_ymin=%d\n',voiInfo.yMin);
fprintf(fp, 'voi_ymax=%d\n',voiInfo.yMax);
fprintf(fp, 'voi_zmin=%d\n',voiInfo.zMin);
fprintf(fp, 'voi_zmax=%d\n',voiInfo.zMax);

%  This converts VOI from C to Matlab values.
% 
fprintf(fp, 'xsize=%d\n',voiInfo.xSize);
fprintf(fp, 'ysize=%d\n',voiInfo.ySize);
fprintf(fp, 'zsize=%d\n',voiInfo.zSize);

disp('Writing means and stats...');

fprintf(fp,'csf_mean=%d\n',1);
fprintf(fp,'gray_mean=%d\n',2);
fprintf(fp,'white_mean=%d\n',3);
fprintf(fp,'stdev=0\n');
fprintf(fp,'confidence=0.00\n');
fprintf(fp,'smoothness=0\n');


% Now write out the raw data in uchar format
fwrite(fp,newimg,'uchar');

fprintf('\nWritten file %s',outFileName);
fprintf('\nvoiInfo structure:\n');

disp(voiInfo);

return;

