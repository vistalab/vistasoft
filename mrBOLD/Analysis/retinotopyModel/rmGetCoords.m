function coords = rmGetCoords(view, model);
% Get the coordinates of the voxels associated with a retinotopy model.
%
% coords = rmGetCoords(view, [model=selected model]);
%
% This is almost the same as rmGet(model, 'coords'), except it allows
% the user to enter the view (instead of grabbing the current view), so
% it should be more robust.
%
% ras, 12/2006.
if notDefined('view'),  view = getCurView;  end
if notDefined('model'), model = viewGet(view, 'rmCurModel'); end
if isnumeric(model)
    allModels = viewGet(view, 'rmModel');
    model = allModels{model};
end

if isfield(model, 'roi_coordinates') && ~isempty(model.roi_coordinates)
    val  = model.roi_coordinates;  
else
    if isfield(view, 'coords') && ~isempty(view.coords)
        coords = view.coords;   % gray / volume
    else        % inplane / flat
        sz = viewSize(view);
        [X Y Z] = meshgrid(1:sz(2), 1:sz(1), 1:sz(3));
        coords = [X(:) Y(:) Z(:)]';
    end
end

return
