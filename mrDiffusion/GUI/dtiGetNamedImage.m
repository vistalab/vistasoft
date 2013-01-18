function [img, mmPerVoxel, mat, valRange] = dtiGetNamedImage(imgStructArray, name)
%
% [img, mmPerVoxel, mat, valRange] = dtiGetNamedImage(imgStructArray, name)
%
% valRange is the [min,max] of the original data.
%
% HISTORY:
% 2003.10.01 RFD (bob@white.stanford.edu) wrote it.

%  I would like to make this routine go away and be replaced with
%  individual dtiGet() calls to the different parameters.
%  mmPerVoxel = dtiGet(handles,'mmPerVoxelCurrent')
%  valRange = dtiGet(handles,'anatomyrange');
%  img = dtiGet(handles,'currentanatomydata')
%  I am having trouble, though getting the .mat return named consistently
%  across the different calls using dtiGet().  So ... I am delaying until I
%  understand all the different dtiGet(handles,'currentXform') and related
%  calls (BW).

index = strmatch(lower(name), lower({imgStructArray.name}));
if(~isempty(index))
    index = index(1);
    img = imgStructArray(index).img;
    mmPerVoxel = imgStructArray(index).mmPerVoxel;
    mat = imgStructArray(index).mat;
    if(isfield(imgStructArray(index), 'minVal'))
        valRange = [imgStructArray(index).minVal, imgStructArray(index).maxVal];
    else
        valRange = [0,1];
    end
else
    img = []; mmPerVoxel = 0; mat = []; valRange = [];
end

return;
