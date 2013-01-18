%outFileName='d:\wade\programming\SureFit\Wade_SureFit.class '; % For FIREBRICK
%inFileName='d:\wade\programming\SureFIt\Wade_tal_raw.L.full.segment_vent_corr.mnc';

outFileName='//ecru/u1/programming/surefit/wade_Volume/Wade_SureFit.class';
inFileName='//ecru/u1/programming/surefit/SUREfit/SEGMENTATION/Wade_tal_raw.L.full.segment_vent_corr.mnc';
paramsFile='//ecru/u1/programming/surefit/SUREfit/SEGMENTATION/';
disp('Reading...');

fid=fopen(inFileName,'rb');
a=fread(fid,inf,'uchar');

fclose(fid);
imDim=[95 244 180]; % Size of the block % We can read these from the params files in the parent of the SureFit SEGMETNATION directory
imOffsets=[43 12 76]; % Voi start % 43
permuteVector=[-2 -3 1];
pVec=abs(permuteVector); % Permutation vector.

    voiInfo.xMin=imOffsets(pVec(1));
    voiInfo.yMin=imOffsets(pVec(2));
    voiInfo.zMin=imOffsets(pVec(3));
    voiInfo.xMax=imOffsets(pVec(1))+imDim(pVec(1))-1;
    voiInfo.yMax=imOffsets(pVec(2))+imDim(pVec(2))-1;
    voiInfo.zMax=imOffsets(pVec(3))+imDim(pVec(3))-1;
    
    voiInfo.xSize=256;
    voiInfo.ySize=256;
    voiInfo.zSize=256;

l=length(a);
a=a(((l-prod(imDim)+1)-4):end-4);
a=uint8(a);

disp('permuting...');

newSize=squeeze(imDim(pVec))

a=reshape(a,imDim);

a=permute(a,pVec);




%a=squeeze(shiftdim(a,1));
disp('Entering into larger array');

% Put a into a larger volume array
b=uint8(zeros(voiInfo.ySize,voiInfo.xSize,voiInfo.zSize));
b((voiInfo.xMin:voiInfo.xMax),(voiInfo.yMin:voiInfo.yMax),(voiInfo.zMin:voiInfo.zMax))=a;

dimsToFlip=find(permuteVector<0)
for thisFlip=dimsToFlip
    b=flipdim(b,thisFlip);
end

disp('Writing...');

count=writeClassFile(b,outFileName,voiInfo);
