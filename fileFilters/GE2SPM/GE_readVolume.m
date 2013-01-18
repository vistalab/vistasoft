function [imageVol, lastfile] = GE_readVolume(baseFileName, volSize, depth, im_offset)
%
%GE_readVolume
% 
% [imageVol, lastfile] = GE_readVolume(baseFileName, [nX nY nZ], depth, im_offset)
%
% reads the volume for passnum from the series which is stored
% starting in startDir and returns the name of the last file read
%
% Souheil J. Inati
% Dartmouth College
% May 2000
% souheil.inati@dartmouth.edu
%
% 2002.01.24 RFD: code needs comments! Apparently, this code assumes a particular dir 
%   structure involving numbered 'run' directories. I simplified things by just assuming
%   all files are in the same dir.
%

% initialize some variables
nX = volSize(1);
nY = volSize(2);
nZ = volSize(3);
sliceSize = nX*nY;
imageVol = zeros(nX, nY, nZ);

for i = 1:nZ
    imNum = sprintf('.%.3d', i);
    imageFile = fullfile('', [baseFileName,imNum]);
    % Open the file
    [fid,message] = fopen(imageFile,'r','b');
    if (fid == -1)
        fprintf('Cannot Open %s.\n',imageFile);
        break
    end
    
    % Skip to the data
    fseek(fid,im_offset,-1);
    % Read the slice
    buffer = fread(fid,sliceSize,sprintf('int%d',depth));
    % append the slice to the imageSet
    imageVol(:,:,i) = reshape(buffer, nX, nY);
    
    % Close the file
    status = fclose(fid);
    
    % Set the lastfile
    lastfile = imageFile;
end

return
