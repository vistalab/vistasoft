function vw = drawROIs(vw, whichRois, method)
%
% vw = drawROIs(vw, <whichRois=get from view>, <method=get from vw>)
%
% Draw the specified ROIs on the view's current display.
%
% whichRois: vector of ROIs in the vw.ROIs field to draw. If omitted,
% parses the view's ROI settings (in vw.ui.showROIs)
% to decide the ROI order:
%   -2: draw all ROIs perimeter
%   -1: draw selected ROIs perimeter
%    0: don't draw any ROIs
%    1: draw selected ROI, boxes around each pixel
%    2: draw all ROIs, boxes around each pixel.
%
% whichRois can also be a cell array of ROI names
%
% method: can be one of the following strings or flags:
%   1 or 'perimeter', outline pixel perimeters
%   2 or 'boxes': boxes around each pixel
%   3 or 'patches': semi-transparent patches. (Matlab 7+ only)
%  If omitted, this is taken from the view struct, or (for hidden views) 
%  defaults to 1.
%
%
% ras 05/06: updated to be much more efficient. Added patches option.
% TODO: re-implement the 'Filled Perimeter' option.
if ~exist('whichRois', 'var') | isempty(whichRois)
    % get from view
    if checkfields(vw, 'ui', 'showROIs')
        if length(vw.ui.showROIs) <= 1
            switch vw.ui.showROIs
                case -2, whichRois = 1:length(vw.ROIs);
                case -1, whichRois = vw.selectedROI;
                case 0, whichRois = [];
                otherwise, whichRois = vw.ui.showROIs;  % manually specify
            end
        else
            whichRois = vw.ui.showROIs;
        end
    else
        whichRois = 1:length(vw.ROIs);
    end        
end

if ~exist('method', 'var') | isempty(method)
    % get from view
    if checkfields(vw, 'ui', 'roiDrawMethod')
        method = vw.ui.roiDrawMethod;
        
    else
        method = 'perimeter';
        
    end
end

% ML 7 check
if isequal(method, 'patches') | isequal(method, 3)
    ver = version;
    if str2num(ver(1)) < 7
        warning('Need MATLAB 7+ to draw patches ... drawing boxes instead')
        method = 'boxes';
    end
end

if iscell(whichRois)    % allow names of ROIs to be passed in
    roiNames = {vw.ROIs.name};
    whichRois = ismember(roiNames, whichRois);
    drawROIs(vw, whichRois, method);
    return
end

%%%%%ensure a field is set for the ROI object handles
N = length(vw.ROIs);
% if ~checkfields(vw, 'ui', 'roiHandles') | length(vw.ui.roiHandles) < N
%     vw.ui.roiHandles = cell(1, N);
% elseif N > length(vw.ui.roiHandles)
%     vw.ui.roiHandles = vw.ui.roiHandles(1:N);
% end
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw the ROIs -- updated algorithms %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch vw.viewType
    case 'Inplane'
        vw = inplaneDrawROIs(vw, whichRois, method); % attached below
        
    case {'Volume' 'Gray'}
        % test for 3-axes view vs. single-orientation view:
        if checkfields(vw, 'ui', 'axiAxesHandle')
            vw = volumeDrawROIs(vw, 1, 1, whichRois, method);
            vw = volumeDrawROIs(vw, 2, 1, whichRois, method);
            vw = volumeDrawROIs(vw, 3, 1, whichRois, method);
        else
            ori = getCurSliceOri(vw);
			slice = viewGet(vw, 'Current Slice');
            vw = volumeDrawROIs(vw, ori, slice, whichRois, method);
        end
        
    case 'Flat'
        vw = flatDrawROIs(vw, whichRois, method); % attached below
        
end


return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function vw = inplaneDrawROIs(vw, whichRois, method);
% Draw specified ROIs according to the specified method, for inplanes
delete( findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line') )
if isempty(vw.ROIs) | whichRois==0, return; end
prefs.method = method;
for r = whichRois
    if isempty(vw.ROIs(r).coords), continue; end
    
    % get color
    color = vw.ROIs(r).color;
    if r==vw.selectedROI, color = viewGet(vw, 'selRoiColor'); end
    
    % delete old ROI hanldes
    try,   delete(vw.ui.roiHandles{r}); end
    % delete(findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line'))
    
    % find coords of ROI within the displayed slice
    pixels = coords2Montage(vw, vw.ROIs(r).coords);   
    
    prefs.color = color; 
    vw.ui.roiHandles{r} = outline(pixels, prefs);
end
return
% /------------------------------------------------------------------/ %






% /------------------------------------------------------------------/ %
function vw = volumeDrawROIs(vw, ori, slice, whichRois, method);
% Draw specified ROIs in an image of the specified orientation, 
% according to the specified method, for volume/gray views
delete( findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line') )
if isempty(vw.ROIs) | whichRois==0, return; end
prefs.method = method;
if isempty(whichRois), return; end

for r = whichRois
    % get color
    color = vw.ROIs(r).color;
    if r==vw.selectedROI, color = viewGet(vw, 'selRoiColor'); end
    
    % delete old ROI hanldes
    try, delete(vw.ui.roiHandles{r}); end
    delete(findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line'))
    
    % find coords of ROI within the displayed slice
    coords = canOri2CurOri(vw, vw.ROIs(r).coords, ori);
	inSlice = find(coords(3,:)==slice);
	if isempty(inSlice)
		vw.ui.roiHandles{r} = [];
		continue
	end
    
    prefs.color = color; 
    vw.ui.roiHandles{r} = outline(coords(1:2,inSlice), prefs);    
end
% /------------------------------------------------------------------/ %






% /------------------------------------------------------------------/ %
function vw = flatDrawROIs(vw, whichRois, method);
% Draw specified ROIs according to the specified method, for flat views
prefs.method = method;
delete(findobj('Parent', vw.ui.mainAxisHandle, 'Type', 'line'))
if isempty(vw.ROIs) | whichRois==0, return; end
for r = whichRois
    % get color
    color = vw.ROIs(r).color;
    if r==vw.selectedROI, color = viewGet(vw, 'selRoiColor'); end
    
    % delete old ROI handles
    if checkfields(vw, 'ui', 'roiHandles') & length(vw.ui.roiHandles) >= r
        delete(vw.ui.roiHandles{r});
    end
    coords = vw.ROIs(r).coords;
	
	if isempty(coords), continue; end
    
    % The FLAT view has a 'rotateImageDegrees' field that
    % specifies a rotation angle for each slice (L or R). 
    % If this is set, then we have to transform the ROIs by this amount as
    % well to make them register with the anatomy and functional data
    coords = rotateCoords(vw, coords);    
	
    % restrict to coords in the slice, zoom
    slice = viewGet(vw, 'Current Slice');  % should really make this work for hidden views
    xZoom = vw.ui.zoom(1:2);
    yZoom = vw.ui.zoom(3:4);
    ok = find(coords(1,:)>=yZoom(1) & coords(1,:)<=yZoom(2) & ...
              coords(2,:)>=xZoom(1) & coords(2,:)<=xZoom(2) & ...
              coords(3,:)==slice);
    coords = coords(:,ok);           	
    
    prefs.color = color; 
    prefs.method = method;
    vw.ui.roiHandles{r} = outline(coords, prefs);
end


return
