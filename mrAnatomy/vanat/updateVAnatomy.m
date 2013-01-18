function updateVanatomy(mmPerPix)
% updateVanatomy([mmPerPix])
%
% mmPerPix is the pixel size in mm/pixel for [rows,cols,planes]
% If not specified, we will try to read it from UnfoldParams.mat.
%
% 00.01.27 RFD
%

disp('Loading vAnatomy...');
[img,mmPerPixFromFile,fPath] = readVolAnat;

if ~exist('mmPerPix','var')
    mmPerPix = mmPerPixFromFile;
end

% Save vAnatomy
%
disp('Saving data...');
path = writeVolAnat(img, mmPerPix);
disp(['updated vAnatomy saved to ' path]);

return;

