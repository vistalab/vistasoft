function images = publish3View(vw, savePath,plotTitle)
%
% images = publish3View(vw, [savePath], [plotTitle]);
%  
% Shows the selected sagittal, coronal, and axial slices
% in a 3View window in a separate figure, with colorbar
% if relevant. 
% 
% If the optional 'savePath' argument is provided, exports
% the figure with the given image path. 
%
% Returns the images in a cell array.
%
% ras, 01/2007.
if notDefined('vw'),      vw = getCurView;      end
if notDefined('savePath'),  savePath = '';          end

% check for 3-view
if ~isfield(vw, 'loc') || isempty(vw.loc)
    error('Not a 3-view or need a location defined in view.loc field.');
end

% get color map
if checkfields(vw, 'ui', 'displayMode')
    mode = sprintf('%sMode', vw.ui.displayMode);
    cmap = vw.ui.(mode).cmap;
end

% ROI prefs
if length(vw.ui.showROIs) <= 1
    switch vw.ui.showROIs
        case -2, roiList = 1:length(vw.ROIs);
        case -1, roiList = vw.selectedROI;
        case 0, roiList = [];
        otherwise, roiList = vw.ui.showROIs;  % manually specify
    end
else
    roiList = vw.ui.showROIs;
end

if roiList==0, roiList = []; end

% get images
[vw axi] = recompute3ViewImage(vw, vw.loc(1), 1);
[vw cor] = recompute3ViewImage(vw, vw.loc(2), 2);
[vw sag] = recompute3ViewImage(vw, vw.loc(3), 3);
axi = ind2rgb(axi, cmap);
cor = ind2rgb(cor, cmap);
sag = ind2rgb(sag, cmap);
images = {sag cor axi};

% open figure
hFig = figure('Color', 'w', 'Position', [0 300 600 400]);
centerfig(hFig, 0);
colormap(cmap);

% sagittal
subplot('Position', [0 0 1/3 1]);
image(sag); axis image; axis off;
drawROIs3View(vw, roiList, gca, 3, vw.loc)
axis([vw.ui.zoom(2,:) vw.ui.zoom(1,:)]);  
sagAxesHandle = gca;

% corornal
subplot('Position', [1/3 0 1/3 1]);
image(cor); axis image; axis off;
drawROIs3View(vw, roiList, gca, 2, vw.loc)
axis([vw.ui.zoom(3,:) vw.ui.zoom(1,:)]);  
corAxesHandle = gca;

% axial
subplot('Position', [2/3 0 1/3 1]);
image(axi); axis image; axis off;
drawROIs3View(vw, roiList, gca, 1, vw.loc)
axis([vw.ui.zoom(3,:) vw.ui.zoom(2,:)]);  
axiAxesHandle = gca;


% Add crosshairs. The function to render crosshairs requires a vw structure
% as input. In order to add cross hairs to the figure to publish, we add
% the 3 axis handles (axial, sagittal, and coronal) to the view struct ui,
% and then call renderCrosshairs. This is a bit of a hack, but it seems
% nicer than writing a new function that renders cross hairs only for
% published figures.
vw.ui.axiAxesHandle = axiAxesHandle;
vw.ui.sagAxesHandle = sagAxesHandle;
vw.ui.corAxesHandle = corAxesHandle;
renderCrosshairs(vw, 1);

if checkfields(vw, 'ui', 'displayMode') && ...
    ismember(vw.ui.displayMode, {'co' 'amp' 'ph' 'map'})
    
    % put up color bar
    addCbarLegend(vw, hFig, .16);    
end

if exist('plotTitle', 'var'), suptitle(plotTitle); end

if ~isempty(savePath)
    saveas(hFig, savePath);
%     close(hFig);
end

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

        if isfield(ui, 'flipLR') && ui.flipLR==1 && ori<3
            % L/R flip affects columns of axi + coronal, but not sag, orientations
            dims = viewGet(vw,'Size');
            pts(2,:) = dims(3) - pts(2,:);
        end
        
        % restrict to voxels within zoom range


        h = outline(pts, prefs);
        if ishandle(h)
            set(h, 'ButtonDownFcn', sprintf('recenter3View(%s,%i);',vw.name, ori));
        end
    end
end

return

