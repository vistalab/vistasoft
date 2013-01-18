function [hdr, mrGrayFileName] = analyze2mrGray(analHeaderFileName,endianType);
% function [V,mrGrayFileName]=analyze2mrGray(analHeaderFileName,endianType);
% Converts Analyze7.5 images to Stanford VISTA lab / mrGray vAnatomy.dat format.
% Analyze headers hold far more information that mrGray volumes. We just toss this 
% information out when we write the mrGray file, but this routine returns the 
% Analyze header info in 'V'.
% Uses the SPM99 spm_vol command to parse the header. Uses misc. VISTA lab routines 
% to clip and write the volume.
% See also mrGray2Analyze
% If you pass in the (optional) endianType it will use this when reading 16bit data 
% files. 
%
% HISTORY:
% ARW 081701
% ARW Added >16 bit data handling 082101
% 02.07.16 RFD (bob@white.stanford.edu) Rewrote code in a more modular format.
% Also added proper image reorientation to make SPM-style analyze format
% files into mrGray orientation.

if (~exist('endianType','var'))
    endianType='';
end
if (~exist('analHeaderFileName','var'))
    analHeaderFileName = '';
end
[img, mmPerPix, hdr] = loadAnalyze(analHeaderFileName, endianType);

% to make analyze data the same orientation as vAnatomy, we reorient the data.
% Note that we assume Analyze orientation code '0'- transverse, unflipped. 
% If that is the case, then the following will make the data look correct in mrGray.
% It will even get left/right correct (left will be left and right right).
img = permute(img,[3,2,1]);

mmPerPix = [mmPerPix(3),mmPerPix(2),mmPerPix(1)];
% flip each slice ud (ie. flip along matlab's first dimension, which is our x-axis)
for(jj=1:size(img,3))
    img(:,:,jj) = flipud(squeeze(img(:,:,jj)));
end
% flip each slice lr(ie. flip along matlab's second dimension, which is our y-axis)
for(jj=1:size(img,3))
    img(:,:,jj) = fliplr(squeeze(img(:,:,jj)));
end
% flip along matlab's third dimension, which is our z-axis
% NO NEED TO DO THIS IF DATA ARE IN STANDARD ANALYZE ORIENTATION
% for(jj=1:size(img,1))
%     img(jj,:,:) = fliplr(squeeze(img(jj,:,:)));
% end

% launch a GUI to find the optimal clip values
img = makeClippedVolume(img);

% Now write out a mrGray file 
mrGrayFileName = writeVolAnat(img, mmPerPix);

return;
