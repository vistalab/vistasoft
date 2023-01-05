function tabMSE = motionCompMeanMSE(meanMap,ROI)
%
%    gb 04/25/05
%
% Computes a matrix of MSE from a cell array of mean maps
% tabMSE(i,j) = motionCompMSE(meanMap{i},ROI,meanMap{j});
%

if ieNotDefined('ROI')
    ROI = '';
end

n = length(meanMap);
tabMSE = zeros(n);

for i = 1:n
    for j = 1:n
        if isempty(meanMap{i}) | isempty(meanMap{j})
            continue;
        end            
        tabMSE(i,j) = motionCompMSE(meanMap{i},ROI,meanMap{j});
    end
end