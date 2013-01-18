function im=analyze2mrLoadRetInplanes(inFileRoot,outFileRoot)
% function outStack=analyze2mrLoadRetInplanes(inFileRoot,outFileRoot)
% Generates a set of anatommical inplanes from Analyze format image stack
% These are used to fool mrInitRet into generating a project when we only have 
% analyze data. See also analyze2mrLoadRetTSeries
% Requires SPM99 routines

% Get the image header
V=spm_vol(inFileRoot);

% Get the image stack
im=spm_read_vols(V);

% mrLoadRet inplanes are x*y+7904 but 
% but the readMRImage routine is normally called with header=0 so all data past the 
% true image size is ignored. So we can get away with just writing these images out as 
% x*y short ints

% Write out I.00x files
% We can also get this from the header
[y x nIms]=size(im)


for t=1:nIms
    suffix=sprintf('%03d',t);
    fileName=[outFileRoot,'I.',suffix];
    thisIm=squeeze(im(:,:,t));
    fid=fopen(fileName,'wb','ieee-be'); % Open file for binary writing
    if (fid)
        written=fwrite(fid,thisIm,'ushort');
    else
        error('Could not open file for writing');
    end
    fclose(fid);
    
end

    