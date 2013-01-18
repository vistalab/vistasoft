function [V,mrGrayFileName]=analyze2mrGrayFunctional(analHeaderFileName,endianType);
% function [V,mrGrayFileName]=analyze2mrGray(analHeaderFileName,endianType);
% Converts Analyze7.5 images to Stanford VISTA lab / mrGray vAnatomy.dat format.
% Analyze headers hold far more information that mrGray volumes. We just toss this information out when we write the mrGray file
% but this routine returns the Analyze header info in 'V'.
% Uses the SPM99 spm_vol command to parse the header. Uses misc. VISTA lab routines to write the volume.
% See also mrGray2Analyze
% If you pass in the (optional) endianType it will use this when reading 16bit data files. Otherwise it assumes 'ieee-be' (non-intel).

% ARW 081701
% ARW Added >16 bit data handling 082101

% Check whether we're reading big or little endian data.
% Default is 'native'; DKP/ Arizona data are 'ieee-be'
if (~exist('endianType','var'))
    endianType='ieee-be';
end

% Read the header
V=spm_vol(analHeaderFileName);

% Now read in the image data
fid=fopen(V.fname,'rb');
if (~fid)
    error (['Could not read header file: ',analHeaderFileName]);
end

im=fread(fid,inf,'uint8');
fclose(fid);
imLen=length(im);

if(imLen~=prod(V.dim(1:3)))
    disp('Wrong data size for 8-bit. Trying 16bit instead');
    fid=fopen(V.fname,'rb',endianType);
  
    im=fread(fid,inf,'uint16');
    fclose(fid);
    imLen=length(im);
    if(imLen~=prod(V.dim(1:3)))
        error ('Not 16 bit either. Quitting');
    end
    
    % Now we have to convert this to 8-bits
    % We're just going to scale for now..
    % Could rescale to (a) The max value, (b) V.dim(4) (the bit depth) , (c) some value we cleverly compute to throw away,say, 5% of the outliers in the histogram
    % Choose (a) for now.
    im=im-min(im(:));
    im=fix(im./max(im(:))*255);

end

img=reshape(im,V.dim(1:3));
mmPerVox=diag(V.mat(1:3,1:3));
mmPerVox=mmPerVox;

% Need to rearrange the image. Analyze data run with sag and axial directions flipped. Also upside down in mrGray...                 
newimg=zeros(V.dim(3),V.dim(2),V.dim(1));
for thisIm=1:(V.dim(2))
   newimg(:,thisIm,:)=flipud(squeeze(img(:,thisIm,:))');
end


% Now write out a mrGray file 
mrGrayFileName = writeVolAnat(newimg, mmPerVox);
