function svmPlotConfusionMatrix(confusionImage,grouplabels,labelsoff)
% Function to plot a confusion image that was created in
% svmConfusionMatrix.

if notDefined('labelsoff'), labelsoff = 0; end
nConditions = length(grouplabels);

figure;
% Clean up the figure junk matlab generates
set(gcf, 'DockControls', 'off');
set(gcf, 'ToolBar', 'none');

% Plot data and begin tidying it up
imagesc(confusionImage);
axis square; % Correct for stretching
set(gca, 'TickLength', [0 0]); % No ticks

if ~labelsoff
    set(gca, 'YTickLabel', grouplabels);
else
    set(gca, 'YTickLabel',[]);
end

% Create rotated labels on the confusion matrix
% Inspired by a script from Andrew Bliss on MATLAB Central, nice!
% http://www.mathworks.com/matlabcentral/fileexchange/8722-rotate-tick-label
set(gca, 'XTickLabel', []); % Clear original x ticks, replace with text command
if ~labelsoff
    xVals = 1:nConditions;
    yVals = repmat(nConditions + (.1 * nConditions), nConditions, 1);
    text(xVals, yVals, grouplabels, 'HorizontalAlignment', 'right', 'rotation', 45, 'FontWeight', 'bold');
    set(gca, 'FontWeight', 'bold');
end

% Shift over and up a bit, to make room for axis labels and legend
set(gca, 'OuterPosition', [0 .05 1 1]);

xLabelPosition = get(get(gca, 'XLabel'), 'Position');
xLabelPosition(2) = nConditions + (.25 * nConditions); % Set position of x label lower than normal
xlabel('Prediction', 'FontSize', 15, 'FontWeight', 'bold', 'Position', xLabelPosition);
ylabel('Query', 'FontSize', 15, 'FontWeight', 'bold');
colorbar;
%colormap gray
colormap autumn