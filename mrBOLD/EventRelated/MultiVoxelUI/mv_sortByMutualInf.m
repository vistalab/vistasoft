function mv = mv_sortByMutualInf(mv,plotFlag,thresh,threshType);
%
% mv = mv_sortByMutualInf([mv],[plotFlag],[thresh],[threshType]);
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
% results, just returns the results in a 'MISorting'
% substruct. 
%
% ras, 05/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('plotFlag')
    plotFlag = 1;
end

if ieNotDefined('thresh')
    thresh = [];
end


if ieNotDefined('thresh')
    threshType = 1;
end

% params
sel = find(tc_selectedConds(mv));
sel = setdiff(sel,13); % GUM FOR E-R ANALYSES
nConds = length(sel);
names = mv.trials.condNames(sel+1); % ignore null

% check if a reliability analysis has been
% run on the data; if not, run it:
if ~isfield(mv,'wta')
    mv = mv_reliability(mv,'plotFlag',0);
end

% grab unsorted voxel data
amps = mv_amps(mv);

% get mutual information for each voxel
mv = mv_mutualInformation(mv,[],'auto',threshType);

% get new row index for voxel data
[ignore rank] = sort(mv.mutualInf.Im);
rank = flipud(rank(:));

% re-sort vox data by this ranking
% (also grab selected conditions only)
sortedAmps = amps(rank,sel);
A1 = mv.wta.amps1(rank,sel);
A2 = mv.wta.amps2(rank,sel);

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
    
    nVoxels = size(A1,1);
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
    mv.MISorting = mv_wtaCurve(mv,A1,A2,1);
    set(gca,'ButtonDownFcn','mv_selectSubset([],[],''MI'');');
    axis square
else
    mv.MISorting = mv_wtaCurve(mv,A1,A2,0);
end    

% add the sorted amps
mv.MISorting.sortedAmps = sortedAmps;
mv.MISorting.A1 = A1;
mv.MISorting.A2 = A2;
mv.MISorting.rank = rank;
mv.MISorting.metric = mv.mutualInf.Im;

% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
end

return
