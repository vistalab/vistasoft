function [V,mrGrayFileName]=analyze2mrGrayClass(analHeaderFileName,outFileName);
% function [V,mrGrayFileName]=analyze2mrGrayClass(analHeaderFileName,outFileName);
% Converts Analyze7.5 images to Stanford VISTA lab / mrGray .class format.
% Analyze headers hold far more information that mrGray volumes. We just toss this information out when we write the mrGray file
% but this routine returns the Analyze header info in 'V'.
% Uses the SPM99 spm_vol command to parse the header. Uses misc. VISTA lab routines (see e.g. writeClassFile) to write the volume.
% See also mrGray2Analyze
% ARW 031402



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

% Need to rearrange the image. Analyze data run with sag and axial directions flipped. Also upside down in mrGray...                 
newimg=zeros(V.dim(3),V.dim(2),V.dim(1));
counter=1;
for thisIm=1:(V.dim(2))
  % newimg(:,thisIm,:)=flipud(squeeze(img(:,thisIm,:))');
  newimg(:,end-(thisIm-1),:)=(squeeze(im(:,thisIm,:))');

end


    voiInfo.xMin=0;
    voiInfo.yMin=0;
    voiInfo.zMin=0;
    voiInfo.xMax=V.dim(1)-1;
    voiInfo.yMax=V.dim(2)-1;
    voiInfo.zMax=V.dim(3)-1;
    
    voiInfo.xSize=V.dim(1);
    voiInfo.ySize=V.dim(2);
    voiInfo.zSize=V.dim(3);
    disp(voiInfo);
    
% Now write out a mrGray file 
outFileName='out.class';

mrGrayFileName = writeClassFile(newimg,outFileName,voiInfo,[0 3 2 1]);
