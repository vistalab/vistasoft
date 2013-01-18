function mv = mv_ampsSubplots(mv, sz, runs, subtractMeans)
%
% mv = mv_ampsSubplots([mv], [sz], [runs], [subtractMeans=0]);
%
% Plot amplitude response vectors for each condition in a 
% separate subplot for comparison. 
%
% If sz = [rows cols] is provided, will arrange the subplots in the
% sepcified number of subplots. Otherwise, arranges the subplots
% in an approximately square array.
%
% If runs is provided, only computes mv_amps for those runs. Otherwise
% uses all runs.
%
% subtractMeans is a flag to remove the mean response across conditions 
% for each voxel (as in Haxby et al., 2001). Default is 0.
%
% ras, 01/2007.
if notDefined('mv'),    mv = get(gcf, 'UserData');      end
if notDefined('sz'),    sz = [];                        end
if notDefined('runs'),  runs = unique(mv.trials.run);   end
if notDefined('subtractMeans'),	subtractMeans = 0;		end

amps = mv_amps(mv, runs);
nVoxels = size(amps, 1);
nConds = size(amps, 2);
sel = find(tc_selectedConds(mv));

if subtractMeans==1
	amps = amps - repmat(nanmean(amps, 2), [1 nConds]);
end

if checkfields(mv, 'ui', 'fig')
	delete(findobj('Parent', mv.ui.fig, 'Type', 'axes'));
end

% compute an order of axes to plot
if ~isempty(sz)
    if length(sz)==2
        nRows = sz(1);
        nCols = sz(2);
    elseif length(sz)==nConds
        % explicit specify axes order
    end
else
    nRows = ceil(sqrt(nConds));
    nCols = ceil(nConds/nRows);
end

ysz = [min(amps(:)) max(amps(:))];

% plot
for c = 1:nConds
    hax(c) = subplot(nRows, nCols, c);

    mv_sparkline(1:nVoxels, amps(:,c), ysz); 
    
    if c == ((nRows-1)*nCols + 1) % lower left-hand corner
        axis on
        xlabel('Voxels', 'FontName', mv.params.font);
        ylabel('% Signal', 'FontName', mv.params.font);
        axis tight
    end
    title(mv.trials.condNames{sel(c)}, 'FontName', mv.params.font, ...
          'FontSize', mv.params.fontsz);
end
normAxes;

axes( hax( (nRows-1)*nCols + 1 ) );         
% tuftify;


return

