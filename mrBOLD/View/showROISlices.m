function [h, montage] = showROISlices(vw, ori, lineWidth);
% [h montage] = showROISlices(view, [ori=get from view], [lineWidth=1.5]);
%
% make a mosaic image (w/ handle h) of
% all the slices in the current view that
% contain the selected ROI.
%
% Currently Volume/Gray view specific.
%
% ras 11/22/04.
if notDefined('vw'),    vw = getCurView;            end
if notDefined('ori'),    ori = getCurSliceOri(vw);    end
if notDefined('lineWidth'),    lineWidth = 1.5;         end

viewType = viewGet(vw,'viewType');

if ~isequal(viewType,'Gray') && ~isequal(viewType,'Volume')
    fprintf('Sorry, currently volume/gray specific now...\n');
    return
end

% initialize montage
montage = [];

% get selected roi
rois = viewGet(vw,'rois');
selRoi = viewGet(vw,'selectedROI');
roi = rois(selRoi);
coords = roi.coords;
    
% get display mode info from view
displayMode = viewGet(vw,'displayMode');
modeInfo = viewGet(vw,[displayMode 'Mode']);
nColors = modeInfo.numColors + modeInfo.numGrays;
if ~isequal(displayMode, 'anat') & isempty(vw.map) & isempty(vw.ph)
    modeInfo = vw.ui.anatMode;
    nColors = modeInfo.numGrays;
end


% figure out which slices it belongs to, depending on
% orientation
coords = canOri2CurOri(vw,coords);
slices = unique(round(coords(3,:)));
nSlices = length(slices);

% other needed params
dims = viewGet(vw,'Size');
if vw.ui.showROIs ~= 0        % ROI drawing prefs
    prefs.method = 2 - (vw.ui.showROIs<0);
    prefs.lineWidth = lineWidth;
    prefs.color = roi.color;
end

% figure out montage size
ncols = ceil(sqrt(nSlices));
nrows = ceil(nSlices/ncols);

% get zoom range
if isfield(vw.ui,'zoom')
    switch ori
        case 1, % axial
            xrng = vw.ui.zoom(3,:);
            yrng = vw.ui.zoom(2,:);
        case 2, % coronal
            xrng = vw.ui.zoom(3,:);
            yrng = vw.ui.zoom(1,:);
        case 3, % sagittal
            xrng = vw.ui.zoom(2,:);
            yrng = vw.ui.zoom(1,:);
    end
    
else
    switch ori
        case 1, xrng = 1:dims(3); yrng = 1:dims(2);
        case 2, xrng = 1:dims(3); yrng = 1:dims(1);
        case 3, xrng = 1:dims(2); yrng = 1:dims(1);
    end

end

% open a figure for the montage
global mrSESSION
oris = {'Axial' 'Coronal' 'Sagittal'};
nm = sprintf('%s Montage, %s [%s]', oris{ori}, roi.name, mrSESSION.sessionCode);
h = figure('Color', 'k', 'Name', nm);
colormap(modeInfo.cmap);

% create the montage
for row = 1:nrows   
    for col = 1:ncols        
        ind = (row-1)*ncols + col;        
        
        if ind <= nSlices
            [vw, im] = recompute3ViewImage(vw, slices(ind), ori);

            if isfield(vw.ui,'flipLR') && vw.ui.flipLR==1 & ori < 3
                im = fliplr(im);
            end

            % put up the image
            xcorner = (col-1) / ncols;
            ycorner = 1 - row/nrows;
            subplot('Position', [xcorner ycorner 1/ncols 1/nrows]);
            imagesc(im, [1 nColors]); axis image; axis off;
            
            % draw ROIs if selected
            if vw.ui.showROIs ~= 0
                ok = find(coords(3,:)==slices(ind));
                outline(coords(1:2,ok), prefs);
            end
            
            % apply zoom
            axis([xrng yrng]);                                    
        end
        
        % add direction labels if appropriate
        if ind==1
            switch ori
                case 1, % axial
                    dX = {'L' ' \leftrightarrow ' 'R'};
                    dY = {'A' ' \leftrightarrow ' 'P'};
                case 2, % coronal
                    dX = {'L' ' \leftrightarrow ' 'R'};
                    dY = {'I' ' \leftrightarrow ' 'P'};
                case 3, % sagittal
                    dX = {'A' ' \leftrightarrow ' 'P'};
                    dY = {'I' ' \leftrightarrow ' 'S'};   
            end
            
            if checkfields(vw, 'ui', 'flipLR') && vw.ui.flipLR==1 && ori<3
                dX = fliplr(dX);
            end
            
            text(xrng(1)+.5*diff(xrng), -5, [dX{:}], ...
                          'FontSize', 12, 'Color', 'w', ...
                          'HorizontalAlignment', 'center');
        end
        
    end   
end

return



% OLD:
%             if view.ui.showROIs ~= 0
%                 % color in ROI locations
%                 subCoords = coords(1:2,coords(3,:)==slices(ind));
%                 roiIndices = sub2ind(size(im),subCoords(1,:),subCoords(2,:));
%                 im(roiIndices) = modeInfo.numGrays + modeInfo.numColors;
%             end
