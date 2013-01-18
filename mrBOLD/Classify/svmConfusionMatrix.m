function confusionImage = svmConfusionMatrix(svm, model, plotMatrixFlag, varargin)
% svmConfusionMatrix(svm, model, varargin)
%   Generate a confusion matrix given an svm struct and a model struct
%   returned from a completed svm run.
%
% If plotMatrixFlag is 1, then the matrix will be plotted in a new figure.
% Default = 1.  Useful to be 0 when scripting.
%
%   No varargins have been specified at this time.
%
% [renobowen@gmail.com 2010]
%
if (~exist('svm', 'var') || isempty(svm) || ~exist('model', 'var') || isempty(model))
    fprintf(1, 'Missing arguments (svm, model, or both).\n');
    return;
end

if notDefined('plotMatrixFlag'), plotMatrixFlag = 1; end

nConditions     = length(svm.grouplabel);
nModels         = length(model);
confusionMatrix = zeros(nConditions);
confusionImage  = zeros(nConditions);

for i = 1:nModels
    nLabels = length(model(i).queryLabels);
    for j = 1:nLabels
        query       = model(i).queryLabels(j);
        prediction  = model(i).predictedLabels(j);

        confusionMatrix(query, prediction) = confusionMatrix(query, prediction) + 1;
    end
end

for i = 1:nConditions
    for j = 1:nConditions
        confusionImage(i, j) = confusionMatrix(i, j) / sum(confusionMatrix(i, :));
    end
end

if plotMatrixFlag
    
    svmPlotConfusionMatrix(confusionImage,svm.grouplabel);
    
%     figure;
%     % Clean up the figure junk matlab generates
%     set(gcf, 'DockControls', 'off');
%     set(gcf, 'ToolBar', 'none');
% 
%     % Plot data and begin tidying it up
%     imagesc(confusionImage);
%     axis square; % Correct for stretching
%     set(gca, 'TickLength', [0 0]); % No ticks
%     set(gca, 'YTickLabel', svm.grouplabel);
% 
%     % Create rotated labels on the confusion matrix
%     % Inspired by a script from Andrew Bliss on MATLAB Central, nice!
%     % http://www.mathworks.com/matlabcentral/fileexchange/8722-rotate-tick-label
%     set(gca, 'XTickLabel', []); % Clear original x ticks, replace with text command
%     xVals = 1:nConditions;
%     yVals = repmat(nConditions + (.1 * nConditions), nConditions, 1);
%     text(xVals, yVals, svm.grouplabel, 'HorizontalAlignment', 'right', 'rotation', 45, 'FontWeight', 'bold');
%     set(gca, 'FontWeight', 'bold');
% 
%     % Shift over and up a bit, to make room for axis labels and legend
%     set(gca, 'OuterPosition', [0 .05 1 1]);
% 
%     xLabelPosition = get(get(gca, 'XLabel'), 'Position');
%     xLabelPosition(2) = nConditions + (.25 * nConditions); % Set position of x label lower than normal
%     xlabel('Prediction', 'FontSize', 15, 'FontWeight', 'bold', 'Position', xLabelPosition);
%     ylabel('Query', 'FontSize', 15, 'FontWeight', 'bold');
%     colorbar;
%     colormap gray

end

return