function h = tuftify(obj);
%
% h = tuftify([obj=gca]);
%
% "Tuftify" a set of axes, making the X and Y axes not intersect unless
% they intersect at (0, 0), and generally making it more in line with the
% conventions suggested by Edward Tufte (see "The Visual Display of
% Quantitative Information").
%
% ras, 08/2006.
if nargin<1, obj=gca; end

AX = axis;
xtick = get(obj, 'XTick');
ytick = get(obj, 'YTick');
color = get(gcf, 'Color');

set(obj, 'TickDir', 'out', 'Box', 'off');

% We're wondering if there is 1 or 2 in xtick because we found a
% discrepancy between two codes that have same name (Dec 2012).
h(1) = line([AX(1) xtick(1)], [AX(3) AX(3)], 'Color', color, 'LineWidth', 2);
h(2) = line([xtick(end) AX(2)], [AX(3) AX(3)], 'Color', color, 'LineWidth', 2);
h(3) = line([AX(1) AX(1)], [AX(3) ytick(1)], 'Color', color, 'LineWidth', 2);
h(4) = line([AX(1) AX(1)], [ytick(end) AX(4)], 'Color', color, 'LineWidth', 2);

return
