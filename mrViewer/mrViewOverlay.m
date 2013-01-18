function ui = mrViewOverlay(ui);
%
%  ui = mrViewOverlay(ui);
%
% Compute overlays for each image,  combine with
% colormap and threshold settings to produce a 
% set of True-Color images to display in
% ui.display.images.
%
% ras 07/05.
if ~exist('ui', 'var') | isempty(ui),  ui = mrViewGet; end
if ishandle(ui),     ui = get(ui, 'UserData');         end

%%%% get needed params
s = ui.settings.space;
b = ui.settings.bounds;
slices = ui.display.slices;
oris = ui.display.oris;
method = ui.settings.mapInterp;

% preference for how to combine multiple overlays:
% 1) average two colors: [1 0 0] + [.2 0 1] => [.6 0 .5];
% 2) add and saturate: [1 0 0] + [.2 0 1] => [1 0 1];
% 3) opaque: [1 0 0] + [.2 0 1] => [.2 0 1]; % last one on top
if ispref('VISTA', 'alphaMethod')
    alphaMethod = getpref('VISTA', 'alphaMethod');
else
    alphaMethod = 1; % average 
end

%%%%% get a list of which overlays to show (ignoring ones that are
%%%%% hidden
isHidden = [ui.overlays.hide];
overlayList = find( ~isHidden );
if isempty(overlayList),  return; end


%%%%% loop across overlays,  computing / displaying each in turn
for i = 1:length(ui.display.images)
    
    imgSz = size(ui.display.images{i});

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % compute each overlay image,  mask of where to show it %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    overlay = []; mask = logical([]);
    for o = overlayList
        ii = find(overlayList==o);
        m = ui.overlays(o).mapNum;
        
        %%%%% get map volume for this timepoint 
        vol = ui.maps(m).data;
        if ndims(vol)>3
            t = ui.overlays(o).subVol;
            vol = vol(:,:,:,t); 
        end

        % get the coords for this slice in the base data space
        imgCoords = mrViewGet(ui, 'DataCoords', i);
        
        % restrict coords to those which pass the threshold
        % of this overlay
        [coords, imageMask] = mrViewRestrict(ui, imgCoords, o, method);
        
        % keep track of the pixels which pass threshold
        mask(:,:,ii) = logical(reshape(imageMask, imgSz));
                
        % xform coords into map data coordinates
        C = inv(ui.maps(m).baseXform) * [coords; ones(1, size(coords, 2))];

        % get the values for the overlay map
        sz = size(vol);
        if(method(1)=='n')
            vals = myCinterp3(vol,[sz(1) sz(2)], sz(3), round(C([2,1,3],:)'), 0.0);
        elseif(method(1)=='l')
            vals = myCinterp3(vol,[sz(1) sz(2)], sz(3), C([2,1,3],:)', 0.0);
        else
            vals = interp3(vol, C(2,:), C(1,:), C(3,:), method);
        end

        % store vals in overlay matrix
        overlaySlice = zeros(imgSz);      
        overlaySlice(imageMask) = vals;
        overlay(:,:,ii) = overlaySlice;
        
        % compute clip vals for overlay
        if isequal(ui.overlays(o).clim, 'auto'),  clim = [min(vals) max(vals)];
        else,                                     clim = ui.overlays(o).clim;            
        end
        
        % update colorbar's color limits, label, units
        ui.overlays(o).cbar.clim = clim;
		ui.overlays(o).cbar.label = ui.maps(m).name;
		ui.overlays(o).cbar.units = ui.maps(m).dataUnits;
    end
   
    % set NaN values to 0
    mask(isnan(overlay)) = false;
    overlay(isnan(overlay)) = 0;
   
    % compute # of overlays present @ each pixel (for transparency)
    overlaysPerPixel = sum(double(mask), 3);    
    
    % find indices of pixels w/ any overlays
    ok = find(overlaysPerPixel>0);
    
    
    % initialize those parts of image to be black:
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % plug in overlays,  taking into account overlap % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % initialize underlay image: black out parts where
    % overlays will be,  make truecolor
    img = rescale(ui.display.images{i}, ui.settings.clim, [1 256]);
    img(ok) = 0; img = ind2rgb(img, ui.settings.cmap);
    
    for o = overlayList
        ii = find(overlayList==o);
        nColors = size(ui.overlays(o).cbar.cmap, 1);

        % get pixel mask for this overlay
        M = mask(:,:,ii);
        
        if any(M(:)>0)                    
            % use overlay data to form an index into the color map:
            vals = overlay(:,:,ii);
            vals = vals(M);
            I = rescale(vals, ui.overlays(o).cbar.clim, [1 nColors]);               

            % manually plug values in to each color channel of image
            % (use the alphaMethod pref to determine how to combine
            % multiple overlays)
            for ch = 1:3
                tmp = img(:,:,ch);
                switch alphaMethod
                    case 1,   % standard alpha -- average colors                        
                        W = 1 ./ overlaysPerPixel(M>0); % weights
                        tmp(M) = tmp(M) + ui.overlays(o).cbar.cmap(I,ch) .* W;
                    case 2,   % add channels and saturate
                        tmp(M) = tmp(M) + ui.overlays(o).cbar.cmap(I,ch);
                        tmp(M) = min(tmp(M), 1);
                    case 3,   % opaque overlays
                        tmp(M) = ui.overlays(o).cbar.cmap(I,ch);                
                end
                img(:,:,ch) = tmp;
            end
        end
    end
    
    ui.display.images{i} = img;
    clear overlay mask
end



return




% % attempt to use alpha map for display
%         % set so that other overlays can peek through
%         mask = uint8(255 .* (1/length(ui.overlays)) .* mask); 
%         % combine color map and overlay values to make 
%         % truecolor image
%         img = ind2rgb(img, ui.overlays(o).cmap);
%        % display image
%         otherDims = setdiff(1:3, ui.display.oris(i));
%         xx = b(otherDims(2), 1):b(otherDims(2), 2);
%         yy = b(otherDims(1), 1):b(otherDims(1), 2);
%         h = image(xx, yy, img, 'AlphaData', mask, ...
%             'AlphaDataMapping', 'none', ...
%             'Parent', ui.display.axes(i));
%         ui.overlays(o).imgHandle(i) = h;

% old comments for above:
% Compute and display overlay images in a mrViewer UI.
%
% NOTE: The method used to display overlay images involves
% using matlab alpha channels,  which makes it more difficult
% to export these images outside matlab. Moreover,  to overlay
% multiple maps which each have different color maps,  ok've found
% it necessary to convert each image to a true color image. 
% Because of the increased memory requirements -- 3 color planes
% plus an alpha mask per overlay image -- ok've decided to 
% combine the computation and display steps into one function.
% 
% If greater use is made of 'hidden' views,  which don't use
% the mrViewer UI but use the structs,  then this should probably
% be rewritten to keep them separate. As well,  it would be probably
% be better to do away with the use of alpha channels,  and just
% produce a single truecolor image for underlay + all overlays. 
% Failing that,  it's probably simpler and more elegant to use
% alpha channels.
%