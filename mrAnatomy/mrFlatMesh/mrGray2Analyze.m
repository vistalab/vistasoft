function  [s]=mrGray2Analyze(mrGrayFileName,analyseFileRoot)
% function  [s]=mrGray2Analyze(mrGrayFileName,analyseFileRoot)
% Converts Stanford VISTA lab / mrGray vAnatomy.dat format to Analyze7.5 format.
% Analyze headers hold far more information that mrGray volumes. We can set mmPerVox but nothing else.
% Uses the SPM99 spm_vol command to parse the header. Uses misc. VISTA lab routines to write the volume.
% See also analyze2mrGray
% Returns 
% s - Analyse header modified after image write.
% ARW 081701
% First read in the mrGray volume. We get mmPerVox from the header.

[imageData,mmPerVox,img_dim]=readVolAnat(mrGrayFileName);

% If mmPerVox is 0, set it to 111
if (prod(mmPerVox)==0)
    mmPerVox=[1 1 1];
end




% Now we have to write out a header file and an image file. 
% We write out the header using the SPM command spm_write_vol
% We dump out the image data as uint8 bytes.

% Use spm_hwrite to write the header.
% FORMAT [s] = spm_hwrite(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP);
% Need to rearrange the image. Analyze data run with sag and axial directions flipped. Also upside down in mrGray...                 
newimg=zeros(img_dim(3),img_dim(2),img_dim(1));
for thisIm=1:(img_dim(2))
   newimg(:,thisIm,:)=flipud(squeeze(imageData(:,thisIm,:))');
end


img_dim=size(newimg);

s=spm_hwrite(analyseFileRoot,img_dim,mmPerVox,1,spm_type('uint8'),0);
V=spm_vol(analyseFileRoot);
V.descrip=['Converted from mrGray file ',mrGrayFileName,' on ',datestr(now)];

s=spm_write_vol(V,newimg);
