function vw = volume3View(vw, loc, xHairs, quickUpdate)
% vw = volume3View(vw, <loc>, <xHairs>, <quickUpdate=1>);
%
% Refresh a volume '3-view': a 'BrainVoyager'-like
% 3-window view, showing sagittal, coronal, and axial slices, at the
% specified location. 'loc' should be a 3-vector containing, respectiveley,
% the Superior/Inferior, Anterior/Posterior, and Right/Left coordinates.
% (For most of the volume anatomies used, S/I range from 1-256, A/P and
% R/L ranges from 1-124.
%
% If omitted, 'loc' is taken from the vw.loc field, or
% failing this set to the middle of the volume.
%
% xHairs: if set to nonzero, will place crosshairs on the current location,
% otherwise will omit them (0 default).
%
% 3/06/03 by ras
% 12/03 ras: using imagesc instead of imshow for now to display
% views, since there's a trickyness in accurately detecting the
% clicked-on location of images put up using imshow.
% 01/04 ras: cleaned up a lot, added 'zoom' field to ui struct allowing
% zooming in on vAnat. (see also zoom3view)
% to do: re-merge ras_recomputeImage with the regular recomputeImage.
% 11/04 ras: added flipping axes option
% 01/07 ras, bw: various ROI display options; trying to make it sensible

%TODO: Remove the input argument 'quickUpdate' - is not used

if ~exist('vw', 'var') || isempty(vw)
    vw = getSelectedVolume;
end

if ~exist('loc','var') || length(loc)<3
    loc = getLocFromUI(vw); 
else
    setLocInUI(vw, loc); 
end
vw.loc = loc;

% get the ui struct from the view
ui = viewGet(vw,'ui');

if ~exist('xHairs','var')
    if isfield(ui, 'crosshairs') && ui.crosshairs==1
        xHairs = 1;
    else
        xHairs = 0;
    end
end

%%%%% check if window exists
winTag = ['3VolumeWindow: ',vw.name];
winExists = findobj('Tag',winTag);

% if window doesn't exist, open the window
if isempty(winExists)
    openRaw3ViewWindow;
else
    % if one or more 3-view figures exist, make the most recent one current
    figure(winExists(end));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ***** Refresh Window ***** %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modeStr=['ui.',ui.displayMode,'Mode'];
mode = eval(modeStr);
cmap = mode.cmap;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get images, apply phase/amp/param maps        %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[vw, axi] = recompute3ViewImage(vw, loc(1), 1);
[vw, cor] = recompute3ViewImage(vw, loc(2), 2);
[vw, sag] = recompute3ViewImage(vw, loc(3), 3);

% not needed for anything, but memory is cheap and may be useful:
vw.ui.image = {axi cor sag};

% flip images if selected
if isfield(ui,'flipAP') && ui.flipAP==1
    sag = fliplr(sag);
    % update loc
end
if isfield(ui,'flipLR') && ui.flipLR==1
    axi = fliplr(axi);
    cor = fliplr(cor);
    % update loc
end


%%%%%%%%%%%%%%%%%%%%%
% put up each image %
%%%%%%%%%%%%%%%%%%%%%
if ~isempty(ui.underlayHandle) && ishandle(ui.underlayHandle(1))
    % handles exist, update image CData only
    set(ui.underlayHandle(1), 'CData', axi);
    set(ui.underlayHandle(2), 'CData', cor);
    set(ui.underlayHandle(3), 'CData', sag);
    quickUpdate = 1; % will bypass axes-related functions below
else
    % create image objects
    axes(ui.axiAxesHandle); cla; %#ok<*MAXES>
    vw.ui.underlayHandle(1) = image(axi); 
    colormap(cmap); axis image, axis off

    axes(ui.corAxesHandle); cla;
    vw.ui.underlayHandle(2) = image(cor); 
    colormap(cmap); axis image, axis off

    axes(ui.sagAxesHandle); cla;
    vw.ui.underlayHandle(3) = image(sag);
    colormap(cmap); axis image, axis off
    
    quickUpdate = 0; % will do zoom, text creation below
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If creating axes, add text annotation, zoom   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if quickUpdate==0

    % zoom in on selected coords %
    if ~isfield(ui,'zoom')
        % initialize to full range if not set
        ui.zoom = [1 size(vw.anat,1);...
            1 size(vw.anat,2);...
            1 size(vw.anat,3)];
    else
        axis(ui.axiAxesHandle, [ui.zoom(3,:) ui.zoom(2,:)]);
        axis(ui.corAxesHandle, [ui.zoom(3,:) ui.zoom(1,:)]);
        axis(ui.sagAxesHandle, [ui.zoom(2,:) ui.zoom(1,:)]);
    end
    
    % set a callback for each image which dynamically updates
    % the location based on where the user clicks
    % callback:
    % vw = recenter3view(vw,[orientationFlag]);
    for i=1:3
        bdf = sprintf('%s=recenter3view(%s,%i); ',vw.name, vw.name, i);
        set(vw.ui.underlayHandle(i), 'ButtonDownFcn', bdf);
    end
    
    % Add titles to indicate directions (esp. L-R: radiological conventions)
    % TO DO: do this at window creation, making them text children of
    % invisible axes (can't use text uicontrols, since they can't use
    % the TeX markup for the arrows)
    txtcol = 'k';
    SIsz = ui.zoom(1,2) - ui.zoom(1,1);
    APsz = ui.zoom(2,2) - ui.zoom(2,1);
    LRsz = ui.zoom(3,2) - ui.zoom(3,1);
    minS = ui.zoom(1,1);
    minA = ui.zoom(2,1);
    minL = ui.zoom(3,1);
    
    axes(ui.sagAxesHandle);
    if isfield(ui,'flipAP') && ui.flipAP==1
        title('Pos \leftrightarrow Ant','FontSize',10,'Color',txtcol);
    else
        title('Ant \leftrightarrow Pos','FontSize',10,'Color',txtcol);
    end
    
    axes(ui.corAxesHandle);
    if isfield(ui,'flipLR') && ui.flipLR==1
        title('Right \leftrightarrow Left','FontSize',10,'Color',txtcol);
    else
        title('Left \leftrightarrow Right','FontSize',10,'Color',txtcol);
    end
    
    
    % the I/S and P/A directions for the cor, axial don't
    % get flipped...
    text(minL-0.2*LRsz,minS + 0.5*SIsz, 'Inf \leftrightarrow Sup', ...
        'FontSize', 10,  'HorizontalAlignment', 'center', ...
        'Rotation', 90, 'Color', txtcol);
    axes(ui.axiAxesHandle);
    text(minL-0.2*LRsz,minA + 0.5*APsz, 'Pos \leftrightarrow Ant', ...
        'FontSize', 10,  'HorizontalAlignment', 'center', ...
        'Rotation', 90, 'Color', txtcol);

    % set tags so we can find each of these axes later
    set(ui.sagAxesHandle, 'Tag', 'sagAxes');
    set(ui.corAxesHandle, 'Tag', 'corAxes');
    set(ui.axiAxesHandle, 'Tag', 'axiAxes');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%              draw ROIs if selected            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove any old ROI objects
hOld = findobj('Tag', sprintf('ROI_Handles_%s', viewGet(vw,'Name')));
delete(hOld);

% draw selected ROIs
if isfield(vw,'ui') & logical(ui.showROIs ~= 0) ...
        & ~isempty(vw.ROIs) & ~viewGet(vw, 'hideVolumeROIs')
	roiList = viewGet(vw, 'ROIsToDisplay');
        
    drawROIs3View(vw, roiList, ui.axiAxesHandle, 1, loc);
    drawROIs3View(vw, roiList, ui.corAxesHandle, 2, loc);
    drawROIs3View(vw, roiList, ui.sagAxesHandle, 3, loc);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add crosshairs to each image to specify current location %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if xHairs
    vw = renderCrosshairs(vw, 1);
end

% Draw colorbar
f = [ui.displayMode,'Mode'];  % field name of display mode
cmap = ui.(f).cmap; 
numGrays = ui.(f).numGrays;
numColors = ui.(f).numColors;
setColorBar(vw, [], [numGrays+1 numGrays+numColors]);

colormap(cmap);

% update the annotation text
curScan     = viewGet(vw, 'curscan');
annotation  = viewGet(vw, 'annotation', curScan);
set(ui.annotationHandle, 'String', annotation);

% lastly, deal with the god-awful global variable issue
if strncmp(vw.name, 'VOLUME', 6)
	updateGlobal(vw);
end

return
% /----------------------------------------------------------------/ %





% /----------------------------------------------------------------/ %
function loc = getLocFromUI(vw)
% reads off the axi,cor, and sag UI edit fields to
% get the current view location.
loc(1) = str2num(get(vw.ui.sliceNumFields(1),'String')); %#ok<*ST2NM>
loc(2) = str2num(get(vw.ui.sliceNumFields(2),'String'));
loc(3) = str2num(get(vw.ui.sliceNumFields(3),'String'));
return
% /----------------------------------------------------------------/ %





% /----------------------------------------------------------------/ %
function vw = setLocInUI(vw, loc)
% sets the current view location in the axi, cor, sag UI edit fields.
set(vw.ui.sliceNumFields(1), 'String', num2str(loc(1)));
set(vw.ui.sliceNumFields(2), 'String', num2str(loc(2)));
set(vw.ui.sliceNumFields(3), 'String', num2str(loc(3)));
return
% /----------------------------------------------------------------/ %




% /----------------------------------------------------------------/ %
function drawROIs3View(vw, roiList, axs, ori, loc)
% draw the ROIs, parsing the relevant settings, on the axes 
% specified by [axs]. This is implemented a little differently
% from drawROIs or drawROIsPerim, in that it doesn't select a given
% orientation each time (which caused some extra time during refreshes).
% roiList is an array into the vw.ROIs field.
ui = vw.ui;

% build prefs for the outline function.  
prefs.method = ui.roiDrawMethod;
prefs.axesHandle = axs;

for r = roiList
    R = vw.ROIs(r);
    if ~isempty(R.coords)
        prefs.color = R.color;
        if r==vw.selectedROI, prefs.color=viewGet(vw,'selRoiColor'); end

        switch ori
            case 1, pts = R.coords([2 3], R.coords(1,:)==loc(1));
            case 2, pts = R.coords([1 3], R.coords(2,:)==loc(2));
            case 3, pts = R.coords([1 2], R.coords(3,:)==loc(3));
        end
		if isempty(pts), continue; end
		
        if isfield(ui, 'flipLR') && ui.flipLR==1 && ori<3
            % L/R flip affects columns of axi + coronal, but not sag, orientations
            dims = viewGet(vw,'Size');
            pts(2,:) = dims(3) - pts(2,:);
        end
        
        % restrict to voxels within zoom range
		zoom = viewGet(vw, 'zoom');
		switch ori
			case 1, zoom = zoom([2 3],:);
			case 2, zoom = zoom([1 3],:);
			case 3, zoom = zoom([1 2],:);
		end
		ok =  pts(1,:) >= zoom(1,1) & pts(1,:) <= zoom(1,2) & ...
				   pts(2,:) >= zoom(2,1) & pts(2,:) <= zoom(2,2) ;
		pts = pts(:,ok);

        h = outline(pts, prefs);
        if ishandle(h)
            set(h, 'ButtonDownFcn', sprintf('recenter3view(%s,%i);',vw.name, ori));
			set(h, 'Tag', sprintf('ROI_Handles_%s', vw.name));
        end
		
    end
end

return
