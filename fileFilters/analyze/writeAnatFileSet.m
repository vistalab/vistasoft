function fileVector=writeAnatFileSet(dataToWrite,fileRoot)
% function fileVector=writeAnatFileSet(dataToWrite,fileRoot)
% Takes a matrix of anatomy data (x*y*nSlices) and writes it out in Analyse format
% We get the mm/vox from mrSESSION
% Example call: dummy=writeAnatFileSet(INPLANE.anat,'./SPM/anat');
mrGlobals;
[x,y,nSlices]=size(dataToWrite);

mmPerVox=mrSESSION.voxelSize;

img_dim=[x,y,nSlices]; % THis is each volume size : x*y*nSlices . The '4' refers to the spm data type 'uint16' : see spm_type
    



% Now we have to write out a header file and an image file. 
% We write out the header using the SPM command spm_write_vol
% We dump out the image data as int16 bytes.

% Use spm_hwrite to write the header.
% FORMAT [s] = spm_hwrite(P,DIM,VOX,SCALE,TYPE,OFFSET,ORIGIN,DESCRIP);
   newimg=squeeze(dataToWrite);
    
    
    thisFileNameRoot=[fileRoot,'_anat'];
        


    s=spm_hwrite(thisFileNameRoot,img_dim,mmPerVox,1,spm_type('int16'),0);
    V=spm_vol(thisFileNameRoot);
    disp(img_dim);
    disp(size(newimg));
    
    
    V.descrip=['Converted from tSeries file in session',mrSESSION.homeDir,' : ',mrSESSION.types(mrSESSION.curType).name,':  on ',datestr(now)];
    
    s=spm_write_vol(V,newimg);
 
