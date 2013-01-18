function ui = mrViewUnderlay(ui);
%
% ui = mrViewUnderlay(ui);
%
% Computes a set of underlay images for display in a mrViewer UI,
% given the selected slices, orientations, and spaces.
%
% Sets the following fields in the ui struct:
%
% ui.display.images: cell of images to show. Returns
% the images in a cell struct, since they may be different sizes.
% Each image is a 2D matrix.
%
% ui.display.order: order in which to display the images
% (for mrViewDisplay). A matrix of size nrows x ncols, where
% nrows and ncols are the # of subplots to be displayed, with
% a 0 where no image will be shown, and an index into the
% images array otherwise.
%
% ui.display.slices = s
%
%
% Also returns a list of slices and orientations for each image.
%
% ras, 07/05.
if ~exist('ui','var') | isempty(ui), ui = mrViewGet; end
if ishandle(ui),    ui = get(ui,'UserData');         end

% init output variables
images = {};
slices = [];
oris = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get volume for this timepoint %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ndims(ui.mr.data)==4
    t = ui.settings.time;
    vol = double(ui.mr.data(:,:,:,t));
else
    vol = double(ui.mr.data);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure out a slice order, w/ corresponding orientations %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch ui.settings.displayFormat
    case 1, % montage
        slice = ui.settings.slice;
        nrows = ui.settings.montageRows;
        ncols = ui.settings.montageCols;

        totalSlices = ui.settings.bounds(ui.settings.ori,2);
        nSlices = round(min(nrows*ncols,totalSlices-slice+1));

        slices = slice:slice+nSlices-1;
        oris = repmat(ui.settings.ori,[1 nSlices]);
        
    case 2, % multiview
        slices = ui.settings.cursorLoc;
        oris = [1 2 3];
        
    case 3, % single slice
        slices = ui.settings.slice;
        oris = ui.settings.ori;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop across slices, generating images %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
method = ui.settings.baseInterp;
for i = 1:length(slices)

    if ui.settings.space==1
        %%%%%%%%%%%%%%%
        % Pixel Space %
        %%%%%%%%%%%%%%%
        switch oris(i)
            case 1, images{i} = squeeze(vol(round(slices(i)),:,:));
            case 2, images{i} = squeeze(vol(:,round(slices(i)),:));
            case 3, images{i} = vol(:,:,round(slices(i)));
        end
    else
        %%%%%%%%%%%%%%%%%%%%%
        % Transformed Space %
        %%%%%%%%%%%%%%%%%%%%%
        % get the coords corresponding to this slice
        b = ui.settings.bounds;
        rng = {[b(1,1):b(1,2)] [b(2,1):b(2,2)] [b(3,1):b(3,2)]};
        rng{oris(i)} = slices(i);
        [X Y Z] = meshgrid(rng{2},rng{1},rng{3});
        coords = [Y(:) X(:) Z(:)]'; clear X Y Z

        % xform from image space -> data space
        % (this is the inverse of the xform we
        % store in spaces)
        s = ui.settings.space;
        if ~isempty(ui.spaces(s).coords)
            % do the direct-coord method
            I = sub2ind(ui.mr.dims(1:3),coords(1,:),coords(2,:),...
                        coords(3,:));
            C = ui.spaces(s).coords(:,I);
        else
            xform = inv(ui.spaces(s).xform);
            C = xform * [coords; ones(1,size(coords,2))];
        end

        % interpolate to get the values at these coords
        images{i} = interp3(vol,C(2,:),C(1,:),C(3,:),method);

        % reshape into image size
        b = b(setdiff(1:3,oris(i)),:); % bounds within the slice
        imgSz = [diff(b,1,2) + 1]';
        images{i} = reshape(images{i},imgSz);

        % mask out NaNs
        images{i}(isnan(images{i})) = 0;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure out order to display images %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch ui.settings.displayFormat
    case 1, % montage view
        order = zeros(ncols,nrows); % will transpose below
        
        % plug in the values, transpose to row-major
        order(1:nSlices) = 1:nSlices;
        order = order';
    case 2, % multi view
        order = [3 2; 0 1]; nrows = 2; ncols = 2;
    case 3, % single slice
        order = 1; nrows = 1; ncols = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assign fields to ui struct %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ui.display.images = images;
ui.display.order = order;
ui.display.slices = slices;
ui.display.oris = oris;

return



