function mv = mv_sortByOmniR(mv,plotFlag);
%
% mv = mv_sortByOmniR([mv],[plotFlag]);
%
% For MultiVoxel UI, sorts voxels by the "omnibus reliability"
% metric, which involves modeling the distribution of mean responses
% across categories for voxels from two subsets of the data.
% [more details as I figure them out]
% 
% Images the voxels sorted by this metric (rows at the top
% will have a higher voxel reliability), and produces
% a performance curve by stepping through progressively
% larger subsets of the data, running the WTA classifier
% on those subsets, to estimate if this metric finds voxels
% that reliability discriminate objects.
%
% if plotFlag is set to 0, the code doesn't visualize the
% results, just returns the results in an 'omniRSorting'
% substruct. 
%
%
%
% ras 05/05.
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('plotFlag')
    plotFlag = 1;
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

% grab mean amplitudes (across all stimuli)
% for each voxel from each subset in the wta analysis:
mu1 = mv.wta.mu1;
mu2 = mv.wta.mu2;
nVoxels = length(mu1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step 1 of omni metric: assume there will
% be some noisy voxels distributed in a Gaussian
% manner about 0, which interfere with the correlated
% positive-amplitude voxels. Assess the variance of
% this distribution by looking at voxels w/ negative
% amplitudes:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
offQuadrants = find(mu1<0 | mu2<0);
stdev1 = nanstd(mu1(offQuadrants));
stdev2 = nanstd(mu2(offQuadrants));
sigma = mean([stdev1 stdev2]);
distFromZero = sqrt(mu1.^2 + mu2.^2);
good = find(distFromZero>sigma);


% for the voxels determined to be in the "noisy" range,
% which is a radius of sigma around 0,  sort by residuals
% to the best-fitted line:
X = [mu1 ones(nVoxels,1)];
[b bCI res resCI stats] = regress(mu2,X,0.05);
metric = 1-abs(res); 

% for 'good' voxels, not within a radius of sigma
% around 0, also sort according to the residuals, but rank
% higher than the potentially noisier ones:
X = [mu1(good) ones(length(good),1)];
[b bCI res resCI stats] = regress(mu2(good),X,0.05);
metric(good) = 10*max(res)-abs(res);  % want lower residuals weighted higher

% get new row index for voxel data
[ignore rank] = sort(metric);
rank = flipud(rank(:))'; % start w/ highest metric vals

% re-sort vox data by this ranking
sortedAmps = amps(rank,:);
A1 = mv.wta.amps1(rank,:);
A2 = mv.wta.amps2(rank,:);

% plot results if selected
if plotFlag==1
    oldaxes = findobj('Type','axes','Parent',gcf);
    delete(oldaxes)
    
    % display a regression, color-coding each point
    % by its approximate rank
    subplot(221);
    regressPlot(mu1,mu2,'x');
    
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

    % show sorted voxels
    subplot(223);
    imagesc(sortedAmps'); % sorted
    set(gca,'YTick',1:nConds,'YTickLabel',names);
    title('Sorted')
    xlabel Voxel
    
    subplot(122);
    mv.voxRSorting = mv_wtaCurve(mv,A1,A2,1);
    set(gca,'ButtonDownFcn','mv_selectSubset([],[],''omniR'');');
    axis square
else
    mv.voxRSorting = mv_wtaCurve(mv,A1,A2,0);
end    

% add the sorted amps
mv.omniRSorting.sortedAmps = sortedAmps;
mv.omniRSorting.A1 = A1;
mv.omniRSorting.A2 = A2;
mv.omniRSorting.sigma = sigma;
mv.omniRSorting.good = good;
mv.omniRSorting.rank = rank;
mv.omniRSorting.metric = metric;

% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
end

return

