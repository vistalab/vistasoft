function coords = rmGetCoords(vw, model)
% Get the coordinates of the voxels associated with a retinotopy model.
%
% coords = rmGetCoords(view, [model=selected model]);
%
% This is almost the same as rmGet(model, 'coords'), except it allows
% the user to enter the view (instead of grabbing the current view), so
% it should be more robust.
%
% ras, 12/2006.
if notDefined('vw'),  vw = getCurView;  end
if notDefined('model'), model = viewGet(vw, 'rmCurModel'); end
if isnumeric(model)
    allModels = viewGet(vw, 'rmModel');
    model = allModels{model};
end

if isfield(model, 'roi_coordinates') && ~isempty(model.roi_coordinates)
    val  = model.roi_coordinates;  
else
    if isfield(vw, 'coords') && ~isempty(vw.coords)
        coords = vw.coords;   % gray / volume
    else        % inplane / flat
        sz = viewGet(vw,'Size');
        [X, Y, Z] = meshgrid(1:sz(2), 1:sz(1), 1:sz(3));
        coords = [X(:) Y(:) Z(:)]';
    end
end

return
