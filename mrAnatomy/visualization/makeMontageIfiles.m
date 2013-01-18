function  img = makeMontageIfiles(baseFileName, imDim, imList, numDigits, byteFlag)
% img = makeMontageIfiles(baseFileName, imDim, imList, [numDigits], [byteFlag])
%
% Reads in reconstructed Pfile images and compiles
% them into an image montage.  
%
% numDigits is the number of digits in the numerical 
% filename extension. Default is 3 (eg. I.001).
%
% EXAMPLE:
%
% if your I-files are in a directory '/red/u4/mri/someIfiles' and
% have the standard 'I.001, I.002, I.003, ...' names, and they are 
% 256x256 images, and there are 100 of them, then try this:
%
%     img = makeMontageIfiles('/red/u4/mri/someIfiles/I', [256 256], [1:100])
%
% To view the resulting image, use something like:
%
%    imagesc(img); colormap(gray); axis image;
%
%
% see also makeCubeIfiles

if(~exist('numDigits') | isempty(numDigits))
    numDigits = 3;
end
if(~exist('byteFlag')) byteFlag = []; end
im3d = makeCubeIfiles(baseFileName, imDim, imList, numDigits, byteFlag);
img = makeMontage(im3d);

return;






















































































































