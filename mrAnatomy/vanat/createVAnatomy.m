function createVanatomy(mmPerPix)
% createVanatomy([mmPerPix])
%
% mmPerPix is the pixel size in mm/pixel for [rows,cols,planes]
%  (defaults to [240/256 240/256 1.2])
%
% 00.01.20 RFD
%

disp('*** WARNING: this function has been renamed!  Use "createVolAnat" instead. ***');
if(exist('mmPerPix','var'))
    createVolAnat(mmPerPix);
else
    createVolAnat;
end
return;


