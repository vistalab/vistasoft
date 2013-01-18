function  [img,mmPerVox] = makeCubeIfiles(baseFileName, imDim, imList, numDigits, byteFlag)
% [img,mmPerVox] = makeCubeIfiles(baseFileName, [imDim], [imList], [numDigits], [byteFlag])
%
% Reads in reconstructed Ifile images and compiles
% them into an image cube.  
%
% if imList unknown, can put empty.
% numDigits is the number of digits in the numerical 
% filename extension. Default is 3 (eg. I.001).
%
% see also makeMontageIfiles
%
% 2001.02.21 RFD: allowed error-recover if an image is missing. 
% 2004.01.23 Junjie: now call getIfileNames.m to auto get all I-files 

if ~exist('imList','var'); imList = []; end;
if exist('numDigits','var');
    allIfileNames = getIfileNames(baseFileName,imList,numDigits);
else
    allIfileNames = getIfileNames(baseFileName,imList);
end
if(~exist('imDim')) 
    imDim = []; 
elseif(length(imDim)==1) 
    imDim = [imDim imDim];
end

if(nargout>1||isempty(imDim))
    % extract header info from first slice:
    [su_hdr1,ex_hdr1,se_hdr1,im_hdr1] = readIfileHeader(allIfileNames{1});
    %mmPerVox = [im_hdr.pixsize_X, im_hdr.pixsize_Y, im_hdr.slthick+im_hdr.scanspacing];
    sliceSkip = im_hdr1.scanspacing;
    mmPerVox = [im_hdr1.pixsize_X, im_hdr1.pixsize_Y, im_hdr1.slthick+sliceSkip];
    if(isempty(imDim))
        imDim = double([im_hdr1.imatrix_X im_hdr1.imatrix_Y]);
    end
end


header = 0;
nImages = length(allIfileNames);
img = zeros(imDim(2),imDim(1),nImages);
if(~exist('byteFlag','var')||isempty(byteFlag))
   if (strcmp(computer,'PCWIN') || strcmp(computer,'GLNX86'))
      byteFlag = 'b';
   else
      byteFlag = 'n';
   end
   % Crude test for byte-swap
   ii = round(nImages./2);
   tempImgB = readRawImage(allIfileNames{ii}, header, imDim, 'b');
   tempImgL = readRawImage(allIfileNames{ii}, header, imDim, 'l');
   r = std(double(tempImgL(:)))./std(double(tempImgB(:)));
   if(r>2) 
       byteFlag = 'b';
   elseif(r<0.5)
       byteFlag = 'l';
   else
       disp(['Byte-flag is indeterminate- trying ' byteFlag '...']);
   end
end

for ii = 1:nImages;
    tempImg = readRawImage(allIfileNames{ii}, header, imDim, byteFlag);
    if(~isempty(tempImg))
        img(:,:,ii) = tempImg;
    end
end


return;
