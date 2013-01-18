function [vw, montage] = recomputeFlatLevelImage(vw,mode)
%
% [vw, img] = recomputeFlatLevelImage(vw,mode)
%
% Recomputes the image for a flat multi-level
% view, taking into account ui settings, and setting
% the overlay for the selected mode (default is the
% view's current display mode). If several levels
% are selected, returns a montage of the levels.
% Does rotations, flips, and zooms separately for
% each level.
%
% The optional second argument returns the image
% (truecolor). The image set in the view's ui
% field is also truecolor, although the image
% displayed in a figure is not technically, b/c
% of old colormap issues (getting the colorbar to
% agree).
%
% ras, 09/04 -- off of inplaneMontage

if ieNotDefined('slices')
    slices = [1:numSlices(vw)];
end

if ieNotDefined('mode')
    mode = vw.ui.displayMode;
end

if ieNotDefined('zoom')
    % check if the view has a zoom assigned in the UI -- if
    % not, get it from the axis bounds
    ui = viewGet(vw,'ui');
    if isfield(ui,'zoom')
        zoom = ui.zoom;
    else
        axes(vw.ui.mainAxisHandle);
        zoom = round(axis);
        if any(zoom < 1) | any(zoom > size(vw.anat,1))
            zoom = [1 size(vw.anat,1) 1 size(vw.anat,2)];
        end
    end
end

% Initialize images
montage = [];
anatIm = [];
overlay = [];

modeInfo = viewGet(vw,[mode 'Mode']);
clipMode = modeInfo.clipMode;

% get info about flat rotations/flips
rotateDeg=0;
[rotations,flipLR]=getFlatRotations(vw); 
rotateDeg=rotations(viewGet(vw, 'Current Slice'));
flipFlag=flipLR(viewGet(vw, 'Current Slice'));    

% Get cothresh, phWindow, and mapWindow from sliders
cothresh = getCothresh(vw);
phWindow = getPhWindow(vw);
mapWindow = getMapWindow(vw);

% Get anatClip from sliders
anatClip = getAnatClip(vw);

% % this may need to be updated if inplane view modes use > 128 colors
% if isequal(mode,'anat')
%     numGrays = 128; numColors = 128;
% else
%     numGrays = 128; numColors = 128;
% end
numGrays = modeInfo.numGrays;
numColors = modeInfo.numColors;

% get # of slices; figure out a good # of rows, cols for montage
slices = getFlatLevelSlices(vw);
[slices nrows ncols] = montageDims(vw);
nSlices = length(slices);

for row = 1:nrows
    rowIm = [];
    
    for col = 1:ncols
        sliceind = (row-1)*ncols + col;
        
        if sliceind <= length(slices)
            % if there's a slice for this row/col
            slice = slices(sliceind);
        else
            % otherwise, set it to show black space below
            slice = slices(end) + 1;
        end
        
        if slice <= slices(end)
            % Get anatomy image
			anatIm = vw.anat(:,:,slice);
			
			% Get overlay
			overlay = [];
			if ~strcmp(mode,'anat')
              overlay = cropCurSlice(vw,mode,slice);
			end
			
			% Select pixels that satisfy cothresh, phWindow, and mapWindow
			pts = [];
			if ~isempty(overlay)
              pts = ones(size(overlay));
              curCo=cropCurSlice(vw,'co',slice);
              curPh=cropCurSlice(vw,'ph',slice);
              curMap=cropCurSlice(vw,'map',slice);
              if ~isempty(curCo) & cothresh>0
                ptsCo = curCo > cothresh;
                pts = pts & ptsCo;
              end
              if ~isempty(curPh)
                if diff(phWindow) > 0
                  ptsPh = (curPh>=phWindow(1) & curPh<=phWindow(2));
                else
                  ptsPh = (curPh>=phWindow(1) | curPh<=phWindow(2));
                end
                pts = pts & ptsPh;
              end
              if strcmp(vw.ui.displayMode, 'amp')
                curAmp = cropCurSlice(vw, 'amp', slice);
                mnv = min(curAmp(:));
                mxv = max(curAmp(:));
                curMap = (curAmp - mnv) ./ (mxv - mnv);
              end
              if ~isempty(curMap)
                ptsMap = (curMap>=mapWindow(1) & curMap<=mapWindow(2));
                pts = pts & ptsMap;
              end
			end
			
			% Rescale anatIm to [1:numGrays], anatClip determines the range
			% of anatomy values that gets mapped to the available grayscales.
			% If anatClip=[0,1] then there is no clipping and the entire
			% range of anatomy values is scaled to the range of available gray
			% scales.
			minVal = double(min(anatIm(:)));
			maxVal = double(max(anatIm(:)));
			anatClipMin = min(anatClip)*(maxVal-minVal) + minVal;
			anatClipMax = max(anatClip)*(maxVal-minVal) + minVal;
			anatIm = (rescale2(double(anatIm),[anatClipMin,anatClipMax],[1,numGrays]));
			
			% Rescale overlay to [numGrays:numGrays+numColors-1]
			if ~isempty(overlay)
               if strcmp(clipMode,'auto')
                  if ~isempty(find(pts));
                     overClipMin = min(overlay(pts));
                     overClipMax = max(overlay(pts));
                  else
                     overClipMin = min(overlay(:));
                     overClipMax = max(overlay(:));
                  end
               else
                  overClipMin = min(clipMode);
                  overClipMax = max(clipMode);
               end
               overlay=rescale2(overlay,[overClipMin,overClipMax],...
                  [numGrays+1,numGrays+numColors]);
			end
			
			% Combine overlay with anatomy image
			if ~isempty(overlay)
               % Combine them in the usual way
               im = anatIm;
               indices = find(pts);
               im(indices) = overlay(indices);
               im(indices) = normalize(im(indices),numGrays+4,numGrays+numColors-4);
			else
               % No overlay.  Just show anatomy image.
               im = anatIm;
			end
                        
            % rotate if selected
            if (rotateDeg | flipFlag) 
                im = imrotate(im,-1*rotateDeg,'bicubic','crop');                   
                if (flipFlag), im=fliplr(im); end 
            end
            
            % zoom
            zoom = round(zoom);
            im = im(zoom(3):zoom(4),zoom(1):zoom(2));
        else
            % there may be blank spaces at the end of the montage image
            im = zeros(size(im));
        end
        
        rowIm = [rowIm im];
    end
    
    montage = [montage; rowIm];
end

% set masked-out (NaN) regions as dark
% rather than white:
indices = isnan(montage);
montage(indices) = 1;

if isfield(vw,'ui')
    if isempty(overlay)
        vw.ui.cbarRange = [];
    else
        vw.ui.cbarRange = [overClipMin overClipMax];  
    end  
    
    % convert to truecolor
    dispMode = sprintf('%sMode',viewGet(vw,'displayMode'));
	cmap = vw.ui.(dispMode).cmap;
    montage = ind2rgb(ceil(montage),cmap); % make truecolor

    % set as the view's image
    vw.ui.image = montage;
end

return


