function tabMI = motionCompMeanMI(meanMap,ROI)
%
%    gb 04/25/05
%
% Computes a matrix of MI from a cell array of mean maps
% tabMI(i,j) = motionCompMI(meanMap{i},ROI,meanMap{j});
%

if ieNotDefined('ROI')
    ROI = '';
end

n = length(meanMap);
tabMI = zeros(n);

for i = 1:n
    for j = 1:n
        if isempty(meanMap{i}) | isempty(meanMap{j})
            continue;
        end            

        tabMI(i,j) = motionCompMI(meanMap{i},ROI,meanMap{j});
    end
end