function mv = mv_sortByVoxR(mv,plotFlag);
%
% mv = mv_sortByVoxR([mv],[plotFlag]);
%
% For MultiVoxel UI, sorts voxels by the "voxel reliability"
% metric, which is computed in mv_reliability, and stored
% in the 'voxR' field of the anal struct that code produces.
% 
% Images the voxels sorted by this metric (rows at the top
% will have a higher voxel reliability), and produces
% a performance curve by stepping through progressively
% larger subsets of the data, running the WTA classifier
% on those subsets, to estimate if this metric finds voxels
% that reliability discriminate objects.
%
% if plotFlag is set to 0, the code doesn't visualize the
% results, just returns the results in a 'voxRSorting'
% substruct. 
%
% ras, 05/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('plotFlag')
    plotFlag = 1;
end

% params
sel = find(tc_selectedConds(mv)) - 1;
% sel = setdiff(sel-1, 13); % GUM FOR E-R ANALYSES
nConds = length(sel);
nRuns = length(unique(mv.trials.run));
names = mv.trials.condNames(sel); % ignore null

%%%%% recompute voxR for current event-related parameters
A1 = mv_amps(mv, 1:2:nRuns);
A2 = mv_amps(mv, 2:2:nRuns);
nVoxels = size(A1,1);
for v = 1:nVoxels
    [R p] = corrcoef(A1(v,sel), A2(v,sel));
    voxR(v) = R(1,2);
end

% grab unsorted voxel data from all runs
amps = mv_amps(mv);

% get new row index for voxel data
[ignore rank] = sort(voxR);
rank = fliplr(rank); % high rank at the top

% re-sort vox data by this ranking
sortedAmps = amps(rank,:);
A1 = A1(rank,:);
A2 = A2(rank,:);

% plot results if selected
if plotFlag==1
    oldaxes = findobj('Type','axes','Parent',gcf);
    delete(oldaxes)
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % display a regression, color-coding each point
    % by its approximate rank
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(221);
    regressPlot(mv.wta.mu1,mv.wta.mu2,'x');
    hold on
    
    binSz = ceil(nVoxels/256); % # voxels per color bin
    ranked1 = repmat(NaN,[binSz 256]);
    ranked2 = repmat(NaN,[binSz 256]);
    ranked1(1:nVoxels) = mv.wta.mu1(rank);
    ranked2(1:nVoxels) = mv.wta.mu2(rank);
    plot(fliplr(ranked1),fliplr(ranked2),'x');
    xlabel('Mean Response, subset 1',...
        'FontName',mv.params.font,'FontSize',10);
    ylabel('Mean Response, subset 2',...
        'FontName',mv.params.font,'FontSize',10);
    setLineColors(jet(256));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % show sorted voxels
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(223);
    imagesc(sortedAmps'); % sorted
    set(gca,'YTick',1:nConds,'YTickLabel',names);
    title('Sorted')
    xlabel Voxels
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Test subplots of the sorted data and plot results
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(122);
    mv.voxRSorting = mv_wtaCurve(mv, A1, A2, 1);
    set(gca, 'ButtonDownFcn', 'mv_selectSubset([],[],''voxR'');');
    axis square
else
    mv.voxRSorting = mv_wtaCurve(mv, A1, A2, 0);
end    

% add the sorted amps
mv.voxRSorting.sortedAmps = sortedAmps;
mv.voxRSorting.ampType = mv.params.ampType;
mv.voxRSorting.A1 = A1;
mv.voxRSorting.A2 = A2;
mv.voxRSorting.rank = rank;
mv.voxRSorting.metric = mv.wta.voxR;

% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
end

return
