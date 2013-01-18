function mv = mv_plotAmps(mv,dims);
%
% mv = mv_plotAmps(mv,dims);
%
% Plot voxel amplitues, along the selected dims.
% dims specifies the order of the following
% conditions to plot: 1) trials 2) voxels 3) conditions.
% If a dimension is omitted, the amps are averaged
% across that dimension. E.g., dims = [2 3] will plot
% voxels on the y axis and conditions on the x axis,
% averaging across trials, while [3 1 2] will plot
% conditions on the y axis over trials on the x axis, with
% nVoxels subplots.
%
% ras, 04/05
if notDefined('mv'),        mv = get(gcf,'UserData');       end
if notDefined('dims'),      dims = [2 3];                   end
if isequal(dims, [2 3])
    % use the dedicated function mv_amps, 
    % which parses different amplitude parameters
    % (not always peak-bsl differences)
    imagesc(mv_amps(mv));
    colormap(mv.params.cmap);
    font = mv.params.font; fontsz = mv.params.fontsz;
    xlabel('Condition', 'FontName', font, 'FontSize', fontsz);
    ylabel('Voxel', 'FontName', font, 'FontSize', fontsz);
    sel = find(tc_selectedConds(mv));
    set(gca, 'XTick', 1:length(sel), 'XTickLabel', mv.trials.condNames(sel));
    mv_plotAmps_colorbar(mv, gca);
    return
end

dimNames = {'Trial' 'Voxel' 'Condition'};
selConds = find(tc_selectedConds(mv));
condNames = mv.trials.condNames(selConds); % ignore null
nConds = length(condNames);

if ~isfield(mv, 'voxAmps')
    mv.voxAmps = er_voxAmpsMatrix(mv.voxData, mv.params);
end

if length(dims) < 3
    nSubplots = 1;
else
    nSubplots = size(mv.voxAmps,dims(3));
    % if the subplots are specifying diff't conditions,
    % only show selected conditions
    if dims(3)==3
        nSubplots = length(selConds);
    end
end

if nSubplots==1
    fontsz = mv.params.fontsz;
else
    fontsz = mv.params.fontsz - 3;
end

% get data to plot; take mean across
% any non-specified dimensions
data = mv.voxAmps(:,:,selConds-1);
avgAcrossDims = setdiff(1:3,dims);
if ~isempty(avgAcrossDims)
    for i = 1:length(avgAcrossDims)
        data = nanmeanDims(data,avgAcrossDims(i));
    end
end

% permute to plotting order
data = permute(data,[dims avgAcrossDims]);

% normalize to fit in the selected color map
cmap = mv.params.cmap;
clim = [min(data(:)) max(data(:))];
% data = double(normalize(data,1,size(cmap,1)));

% delete existing axes
other = findobj('Type','axes','Parent',gcf);
delete(other);
nrows = ceil(sqrt(nSubplots));
ncols = ceil(nSubplots/nrows);

for z = 1:nSubplots
    axs(z) = subplot(nrows,ncols,z);
    imagesc(data(:,:,z));
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
	
    xlabel(dimNames{dims(2)},'FontName',mv.params.font,...
        'FontSize',fontsz);
	
    if length(dims)>=2 & dims(2)==3
        set(gca,'XTick',1:nConds,'XTickLabel',condNames);
	end
	
    if length(dims)==3 & dims(3)==3
        title(condNames{z},'FontName',mv.params.font,...
            'FontSize',fontsz+2);
	end
	
    % correct for long x/y tick labels
    if nSubplots > 1
        xtick = get(gca,'XTick');
        ytick = get(gca,'YTick');
        if xtick(end) > 100
            xtick = [xtick(1) xtick(end)];
            set(gca,'XTick',xtick);
        end
        if ytick(end) > 100
            ytick = [ytick(1) ytick(end)];
            set(gca,'YTick',ytick);
        end
    end
end

% add colorbar
mv_plotAmps_colorbar(mv, axs);

return
% /-------------------------------------------------------------------/ %



% /-------------------------------------------------------------------/ %
function mv_plotAmps_colorbar(mv, axs);
% create a colorbar for the amplitude plots, moving the axes
% to the side.
% move the axes to the side to make way for colorbar
for z = 1:length(axs)
    pos = get(axs(z),'Position');
    pos(1) = pos(1) - 0.03;
    pos(3) = pos(3) * 0.9;
    set(axs(z),'Position',pos)
end
% make a colorbar
cbar = axes('Position',[.88 .1 .03 .8]);
colorbar(cbar,'peer',axs(z));
axes(cbar);
ylabel('Amplitude [% Signal]','FontName',mv.params.font,...
    'FontSize',mv.params.fontsz)
return
