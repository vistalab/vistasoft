function h = legendPanel(names, colors, sz);
%
% h = legendPanel(names, colors, [sz=.16]);
% 
% Create a legend in a separate panel to a figure, attached to the right
% hand side. Useful if you're plotting several subplots, and don't want to
% attach the legend to any one panel, but to the figure as a whole. Also,
% doesn't try to figure out the data series, like the matlab builtin LEGEND
% function, but just takes what the user specifies.
%
% names is a cell array of name labels to use.
%
% sz is the size of the panel relative to the figure [default .16]. 
%
% colors is a cell array of color specifications for each label. 
% Colors can be specified as [R G B] triplets, or color letters a la the
% PLOT command.
%
% Returns a handle to the panel h. To hide/show the legend, you can use
% mrvPanelToggle(h).
%
% If this ends up being useful, I'll add support for line styles etc. 
%
% ras, 08/2006.
if nargin<1, help(mfilename); error('Not enough input args.'); end

if notDefined('colors'), colors = get(gca, 'ColorOrder'); end
if notDefined('sz'), sz = .2; end

if isnumeric(colors), colors = colorMtx2Cell(colors); end

% create the panel
h = mrvPanel('right', sz);
    
% the legend images will be an array of subplots, with at
% most 20 rows per column:
N = length(names);
ncols = ceil(N/20);
nrows = min(20, N);

for i = 1:length(names)
    row = mod(i-1, 20) + 1;
    col = ceil(i/20);
    pos = [.8*(col-1)/ncols,  .96-row*.05,  .1,  .02];
    axes('Position', pos, 'Parent', h);
    axis([0 1 0 1]); axis off; 
    set(gca, 'Box', 'off');
    hp = patch([0 1 1 0], [0 0 1 1], colors{i});
    set(hp, 'EdgeColor', 'none');
    text(1.5, 1.3, names{i}, 'FontSize', 12, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
end



return
% /----------------------------------------------------------------/ %




% /----------------------------------------------------------------/ %
function colors = colorMtx2Cell(mtx);
% given an Nx3 color matrix, convert to a cell array of entries
for i = 1:size(mtx, 1)
    colors{i} = mtx(i,:);
end
return
