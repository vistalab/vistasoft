function mr = mrCrop(mr, crop, savePath, func)
%
% mr = mrCrop([mr=dialog], [crop=get from GUI], [savePath], [functionalMR]);
%
% Crop each slice of an mr object, saving if prompted. 
%
% INPUTS:
%   mr: MR data structure to crop.
%   crop: 2 x 2 crop vector of format [x1 y1; x2 y2]. Each slice / time point
%       in mr will be cropped between rows y1:y2, and columns x1:x2.
%       If omitted, the crop will be gotten interactively with mrCropGUI.
%   savePath: if provided, will save the cropped mr object in the specified
%       path.
%   functionalMR: another mr struct for a coregistered functional time
%       series. If this is provided, mrCrop will adjust the crop so that
%       it is flush with the functional voxels (which may be larger than
%       the mr voxels). I.e., the same physical extent of cropping, 
%       applied to the functionals, will leave an integer number of 
%       functional voxels.
%
% OUTPUTS:
%   mr: cropeed mr struct.
%
% ras,  02/02/07
if notDefined('mr'),        mr = mrLoad;            end
if notDefined('crop'),      crop = mrCropGUI(mr);   end
if notDefined('savePath'),  savePath = '';          end
if notDefined('func'),      func = [];              end

mr = mrParse(mr);

x1 = crop(1,1); x2 = crop(2,1);
y1 = crop(1,2); y2 = crop(2,2);

if ~isempty(func)
    func = mrParse(func);
    
    if ~isequal(mr.extent(1:2), func.extent(1:2))
        error('functional data doesn''t cover the same extent as mr.');
    end
    
    scaleFactor = func.voxelSize(1:2) ./ mr.voxelSize(1:2);
    
    % the way we know the crops won't partial volume the functionals is if
    % the value of each corner, mod the scale factor, is non-zero. So,
    % subtract this remainder out:
    x1 = x1 - mod(x1, scaleFactor(2));
    x2 = x2 - mod(x2, scaleFactor(2));
    y1 = y1 - mod(y1, scaleFactor(1));
    y2 = y2 - mod(y2, scaleFactor(1));
    
    crop = [x1 x2; y1 y2];
end

% crop
mr.data = mr.data(y1:y2,x1:x2,:,:);

% update info marking the crop on the original size
mr.info.crop = crop;
mr.info.fullSize = mr.dims(1:2);
mr.dims = size(mr.data);
if length(mr.voxelSize) > length(mr.dims)
    mr.dims( length(mr.voxelSize) ) = 1;
end
mr.extent = mr.voxelSize .* mr.dims;

if ~isempty(savePath)
    mrSave(mr, savePath);
end

return
