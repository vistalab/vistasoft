function mv = mv_plotVoxData(mv,dims);
%
%  mv = mv_plotVoxData(mv,dims);
%
% MultiVoxel UI:
% Plot voxel data along 2-3 dimensions, 
% averaging across the others.
%
% ras, 04/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('dims')
    dims = [2 3];
end

dimNames = {'Trial' 'Voxel' 'Condition'};
selConds = find(tc_selectedConds(mv));
condNames = mv.trials.condNames(selConds); % ignore null
nConds = length(condNames);

if length(dims) < 3
    nSubplots = 1;
else
    nSubplots = size(mv.voxAmps,dims(3));
end

if nSubplots==1
    fontsz = mv.params.fontsz;
else 
    fontsz = mv.params.fontsz - 3;
end

% get data to plot; take mean across
% any non-specified dimensions
data = mv.voxData(:,:,:,selConds-1);
avgAcrossDims = setdiff(1:4,dims);
if ~isempty(avgAcrossDims)
    for i = 1:length(avgAcrossDims)
        data = nanmeanDims(data,avgAcrossDims(i));
    end
end

% permute to plotting order
data = permute(data,[dims avgAcrossDims]); 

% normalize to fit in the selected color map
cmap = mv.params.cmap;
data = double(normalize(data,1,size(cmap,1)));

% delete existing axes
other = findobj('Type','axes','Parent',gcf);
delete(other);

nrows = ceil(sqrt(nSubplots));
ncols = ceil(nSubplots/nrows);

for z = 1:nSubplots
    subplot(nrows,ncols,z);
    image(data(:,:,z));
    colormap(cmap);
    
    % check for conditions labeling:
    % we'll treat that specially, labeling
    % each condition separately
    if dims(1)==3
        set(gca,'YTick',1:nConds,'YTickLabel',condNames);
    else
        ylabel(dimNames{dims(1)},'FontName',mv.params.font,...
                'FontSize',fontsz);
    end

    if length(dims)>=2 & dims(2)==3
        set(gca,'XTick',1:nConds,'XTickLabel',condNames);
    else
        xlabel(dimNames{dims(2)},'FontName',mv.params.font,...
                'FontSize',fontsz);
    end
    
    if length(dims)==3 & dims(3)==3
        title(condNames{z},'FontName',mv.params.font,...
            'FontSize',fontsz+2);
    end
end


return
