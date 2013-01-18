function h = addRoiLegend(view, parent, roiList);
% h = addRoiLegend(view, [parent=view fig], [roiList='all']);
%
% Add a uipanel to the right of the parent figure, with a legend indicating
% the colors of each of the view's ROIs
%
% ras, 08/03/06, added to aid meshMultiAngle utilities
if notDefined('view'),	 view = getCurView;				 end
if notDefined('parent'), parent = view.ui.windowHandle;  end
if notDefined('roiList'), roiList = viewGet(view, 'ROIList'); end

if isempty(roiList)
	% no ROIs to label
	return
end

h = mrvPanel('right', .16, parent);
set(h, 'BackgroundColor', get(gcf,'Color'), 'BorderType', 'none');
  

% the legend images will be an array of subplots, with at
% most 20 rows per column:
N = length(roiList);
ncols = ceil(N/20);
nrows = min(20, N);

% for each ROI, make a patch with 
% that ROI's color, and the name
for j = 1:N
    r = roiList(j);
    row = mod(j-1, 20) + 1;
    col = ceil(j/20);
    pos = [.8*(col-1)/ncols,  .96-row*.05,  .1,  .02];
    axes('Position', pos, 'Parent', h);
    axis([0 1 0 1]); axis off; 
    set(gca, 'Box', 'off');
    hp = patch([0 1 1 0], [0 0 1 1], view.ROIs(r).color);
    set(hp, 'EdgeColor', 'none');
    name =  view.ROIs(r).name;
    name(name=='_') = '-';
    text(1.5, 1.3, name, 'FontSize', 12, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end


return
