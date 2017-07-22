function anal = mv_wtaCurve(mv,A1,A2,plotFlag);
%
% anal = mv_wtaCurve(mv,A1,A2,plotFlag);
%
% For MultiVoxel UI, take voxel amplitudes specified
% in the amps matrices A1 and A2 (taken from an odd/even
% WTA classifier if unspecified), and compare them across
% progressively larger subsets of voxels, starting with
% the first 10 voxels and proceeding until the subset
% contains all voxels. 
%
% These curves are expected to be useful only if the voxels
% in A1 and A2 have been sorted according to some criterion,
% otherwise, the smaller subsets are not expected to be 
% any more informative of the stimulus set than the larger 
% ones. See mv_sortByVoxR for an example.
%
%
% ras, 05/05
if ieNotDefined('mv')
    mv = get(gcf,'UserData');
end

if ieNotDefined('A1')
    % get from wta struct
    if ~isfield(mv,'wta')
        mv = mv_reliability(mv);
    end
    A1 = mv.wta.amps1;
end

if ieNotDefined('A2')
    % get from wta struct
    if ~isfield(mv,'wta')
        mv = mv_reliability(mv);
    end
    A2 = mv.wta.amps2;
end

if ieNotDefined('plotFlag')
    plotFlag = 1;
end

%%%%% params
nSteps = 40;

%%%%% subselect selected conditions
sel = find(tc_selectedConds(mv))-1;
names = mv.trials.condNames(sel+1); % ignore 1st, null name

%%%%% initalize output vals
anal.omniR = [];
anal.corrRvals = [];
anal.meanR = [];
anal.semR = [];
anal.pctCorrect = [];
anal.subsetSize = round(linspace(10,size(A1,1),nSteps));
anal.subsetSize(end) = size(A1,1);

%%%%% step through voxel sizes
wb = mrvWaitbar(0,'Stepping through R values...');
for step = 1:nSteps
    subset = 1:anal.subsetSize(step);
    tmpanal = er_wtaClassifier(A1(subset,:), A2(subset,:), [0 0 0]);
    
    anal.omniR = [anal.omniR tmpanal.omnibusR];
    anal.corrRvals = cat(3,anal.corrRvals,tmpanal.corrRvals);
    anal.pctCorrect = [anal.pctCorrect tmpanal.pctCorrect];
    anal.meanR = [anal.meanR; tmpanal.meanR];
    anal.semR = [anal.semR; tmpanal.semR];
    
    mrvWaitbar(step/nSteps,wb);
end
close(wb);

%%%%% plot results if selected
if plotFlag==1
% 	anal.plotHandle = figure('Color','w');
	cla
	hold on
	plot(anal.subsetSize,anal.omniR,'k--','LineWidth',2);
	plot(anal.subsetSize,anal.pctCorrect./100,'r','LineWidth',1.5);
	xlabel('Subset Size, Voxels','FontSize',12);
	ylabel('R (black) | Proportion Correct (red)','FontSize',12);
	legend('Omnibus R','% Correct');
end

%%%%% if a UI exists, set as user data
if isfield(mv.ui,'fig') & ishandle(mv.ui.fig)
    set(mv.ui.fig,'UserData',mv);
end

return

