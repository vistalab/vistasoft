function cmap = overlapCmap(numGrays,numColors,rgyFlag)
%
% cmap = overlapCmap(numGrays,numColors,rgyFlag)
% 
% Makes color map array with numGrays grays,
% and a numColors sub-map that's divided into
% 3 color bands (red, green, yellow, or red,
% blue purple, depending on the setting of rgyFlag).
% Used for visualizing overlap maps, though may be
% useful for other purposes.
%
% ras 2/04
if ieNotDefined('rgyFlag')
    rgyFlag = 1;
end

if ~exist('numGrays','var')
    numGrays=128;
end
if ~exist('numColors','var')
    numColors=128;
end

if rgyFlag==1
    % red/green/yellow colors
    colA = [.9 0 0];
    colB = [0 .9 0];
    colC = [.9 .9 0];
else
    % red/blue/purple colors
    colA = [.9 0 0];
    colB = [0 0 .9];
    colC = [.9 0 .9];
end    


rngA = 1:round(numColors/3);
rngB = round(numColors/3)+1:ceil((2/3)*numColors);
rngC = ceil((2/3)*numColors)+1:numColors;

colors = zeros(numColors,3);
colors(rngA,:) = repmat(colA,[length(rngA) 1]);
colors(rngB,:) = repmat(colB,[length(rngB) 1]);
colors(rngC,:) = repmat(colC,[length(rngC) 1]);

cmap = [gray(numGrays); colors];

return
