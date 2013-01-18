function h = fancyHist(X, Y, mu, sigma, colors);
%
% h = fancyHist(X, Y, mu, sigma, <colors>);
%
% A 'fancy' visualization of of histograms, generally for multiple
% overlapping distributions. This code shows bar plots (w/ decent spacing, no lines)
% of each of the columns in Y, at the x locations in X. Above the histogram,
% the code will plot the mean +/- std of each distribution for comparison. If the optional 
% color argument is set (a cell array of [r g b] triplets or letter 
% designators -- see HELP PLOT), will also set the color of the bars
% accordingly.
%
%
% ras, 09/2006
if nargin<2, help(mfilename); error('Not enough input args.'); end

% make X match the size of Y
if size(X,1)==1, X = X(:); end
if size(X,2) ~= size(Y,2), X = repmat(X(:,1), [1 size(Y,2)]); end

% plot the main bars
h = bar(X, Y, 'LineStyle', 'none', 'Barwidth', 1.02);
hold on
axis tight
% 
% 
% % figure out how much we need to zoom out to leave space for the 
% % summary plots:
% nY = size(Y, 2);
% AX = axis;
% AX2 = AX;
% dy = .06 * diff(AX(3:4));
% AX2(4) = AX2(4) + (nY+1)*dy;
% axis(AX2);
oldYTick = get(gca, 'YTick'); % get tick points, since the summary
% 						      % will zoom out

% set bar / symbol line colors, if requested
if exist('colors', 'var')
    setLineColors(colors);
end
% 
% if exist('mu', 'var') & exist('sigma', 'var')
%     % plot summary plots
%     co = get(gca, 'ColorOrder');
%     for ii = 1:nY
%         yy = AX(4) + (ii * dy);
%         m = mu(ii); s = sigma(ii);
%         hold on
%         plot(m, yy, 'o', 'Color', co(ii,:));
%         line([m-s m], [yy yy], 'Color', co(ii,:), 'LineWidth', 2);
%         line([m m+s], [yy yy], 'Color', co(ii,:), 'LineWidth', 2);
%         plot(m-s, yy, '.', 'Color', co(ii,:));
%         plot(m+s, yy, '.', 'Color', co(ii,:));
%     end
% end

set(gca, 'Box', 'off', 'YTick', oldYTick)

return

